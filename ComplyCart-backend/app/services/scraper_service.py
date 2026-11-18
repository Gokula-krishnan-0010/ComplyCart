import os
import json
import random
import time
import asyncio
from typing import Dict, Any, List
from urllib.parse import urlparse
from bs4 import BeautifulSoup
import requests
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

# Custom Scraper Exceptions
class ScrapeError(Exception):
    """Base scraper exception"""
    pass

class ScrapeTimeoutError(ScrapeError):
    """Raised when a request or rendering times out"""
    pass

class ScrapeBlockedError(ScrapeError):
    """Raised when request is blocked or captcha is detected"""
    pass

# Load selectors configuration at startup
SELECTORS_FILE_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "core",
    "scraper_selectors.json"
)

try:
    with open(SELECTORS_FILE_PATH, "r", encoding="utf-8") as f:
        SCRAPER_SELECTORS = json.load(f)
except Exception:
    SCRAPER_SELECTORS = {}

USER_AGENTS = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:123.0) Gecko/20100101 Firefox/123.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3 Safari/605.1.15"
]

def detect_platform(url: str) -> str:
    parsed = urlparse(url)
    domain = parsed.netloc.lower()
    if "amazon" in domain:
        if domain.endswith(".in"):
            return "amazon.in"
        return "amazon.com"
    elif "flipkart" in domain:
        return "flipkart.com"
    return "generic"

def check_blocking(html_content: str, status_code: int = 200) -> None:
    if status_code in (403, 503):
        raise ScrapeBlockedError(f"HTTP status code {status_code} indicates blocking.")
    
    soup = BeautifulSoup(html_content, "html.parser")
    title_text = soup.title.string.lower() if soup.title else ""
    page_text = html_content.lower()
    
    blocking_keywords = [
        "captcha", "robot check", "human verification", 
        "security check", "are you a human", "distil networks"
    ]
    
    if any(kw in title_text for kw in blocking_keywords) or any(kw in page_text[:1000] for kw in blocking_keywords):
        raise ScrapeBlockedError("Access blocked or captcha detected.")

def parse_with_selectors(html_content: str, platform: str) -> Dict[str, Any]:
    soup = BeautifulSoup(html_content, "html.parser")
    selectors = SCRAPER_SELECTORS.get(platform, SCRAPER_SELECTORS.get("generic", {}))
    
    # Title
    title = ""
    for sel in selectors.get("title_selectors", []):
        el = soup.select_one(sel)
        if el:
            title = el.get_text(strip=True)
            break
            
    # Price
    price = ""
    for sel in selectors.get("price_selectors", []):
        el = soup.select_one(sel)
        if el:
            price = el.get_text(strip=True)
            break
            
    # Seller
    seller = ""
    for sel in selectors.get("seller_selectors", []):
        el = soup.select_one(sel)
        if el:
            seller = el.get_text(strip=True)
            break
            
    # Description/Specification (combine all matching blocks)
    desc_parts = []
    for sel in selectors.get("description_selectors", []):
        for el in soup.select(sel):
            text = el.get_text(separator="\n", strip=True)
            if text:
                desc_parts.append(text)
    description = "\n".join(desc_parts) if desc_parts else ""
    
    # Image URLs
    images = []
    for sel in selectors.get("image_selectors", []):
        for el in soup.select(sel):
            src = el.get("src") or el.get("data-old-hires") or el.get("data-a-dynamic-image")
            if src:
                # If dynamic image json, take first url key
                if src.startswith("{"):
                    try:
                        keys = list(json.loads(src).keys())
                        if keys:
                            images.append(keys[0])
                    except:
                        pass
                else:
                    images.append(src)
    
    return {
        "title": title,
        "price": price,
        "seller": seller,
        "description": description,
        "image_urls": list(set(images))
    }

# Retrying only on transient errors
@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=6),
    retry=retry_if_exception_type((requests.RequestException, requests.ConnectionError, requests.HTTPError)),
    reraise=True
)
def _perform_static_request(url: str, headers: dict) -> requests.Response:
    try:
        return requests.get(url, headers=headers, timeout=10)
    except requests.Timeout as e:
        raise ScrapeTimeoutError(f"Static request timed out: {str(e)}")
    except requests.RequestException as e:
        raise e

def _run_playwright_sync(url: str, platform: str) -> Dict[str, Any]:
    import asyncio
    import sys
    from playwright.sync_api import sync_playwright
    
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
        
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            user_agent=random.choice(USER_AGENTS),
            viewport={"width": 1280, "height": 800}
        )
        page = context.new_page()
        
        try:
            page.goto(url, timeout=20000, wait_until="domcontentloaded")
        except Exception as e:
            if "timeout" in str(e).lower():
                raise ScrapeTimeoutError("Playwright headless render timed out.")
            raise e
            
        content = page.content()
        check_blocking(content)
        
        data = parse_with_selectors(content, platform)
        data["scraped_via"] = "playwright"
        browser.close()
        return data


async def scrape_product(url: str) -> Dict[str, Any]:
    """
    Scrapes a product page by URL. Uses static BS4 first, fallback to Playwright in separate thread if needed.
    """
    platform = detect_platform(url)
    
    # Proactive Jitter: 1-2s delay
    jitter = random.uniform(1.0, 2.0)
    time.sleep(jitter)
    
    headers = {
        "User-Agent": random.choice(USER_AGENTS),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
        "Connection": "keep-alive",
        "Upgrade-Insecure-Requests": "1"
    }
    
    static_success = False
    html_content = ""
    status_code = 200
    
    try:
        response = _perform_static_request(url, headers)
        html_content = response.text
        status_code = response.status_code
        # Detect block/captcha
        check_blocking(html_content, status_code)
        static_success = True
    except ScrapeBlockedError as e:
        # Re-raise blocked immediately so we don't retry or proceed blindly
        raise e
    except Exception as e:
        # For other request exceptions, we will proceed to Playwright fallback
        if isinstance(e, ScrapeTimeoutError):
            # We can try Playwright
            pass
            
    if static_success:
        data = parse_with_selectors(html_content, platform)
        # Check if static scraping returned sufficient data
        if data.get("title") and data.get("price"):
            data["scraped_via"] = "static"
            return data
            
    # Trigger Headless Playwright Fallback in separate thread executor
    loop = asyncio.get_running_loop()
    try:
        return await loop.run_in_executor(None, _run_playwright_sync, url, platform)
    except ScrapeBlockedError as e:
        raise e
    except Exception as e:
        if "timeout" in str(e).lower() or isinstance(e, ScrapeTimeoutError):
            raise ScrapeTimeoutError(f"Headless fallback timed out: {str(e)}")
        raise ScrapeError(f"Headless fallback failed: {str(e)}")
