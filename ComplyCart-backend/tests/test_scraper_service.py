import os
import pytest
from unittest.mock import patch, MagicMock
from app.services.scraper_service import (
    parse_with_selectors, 
    scrape_product, 
    ScrapeBlockedError, 
    ScrapeTimeoutError
)

FIXTURES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "fixtures")

def _read_fixture(filename: str) -> str:
    path = os.path.join(FIXTURES_DIR, filename)
    with open(path, "r", encoding="utf-8") as f:
        return f.read()

def test_amazon_parsing_offline():
    html = _read_fixture("amazon_product.html")
    parsed = parse_with_selectors(html, "amazon.in")
    
    assert parsed["title"] == "Super Organic Tea 100g Bag"
    assert parsed["price"] == "Rs. 250.00"
    assert "GreenTea Organics" in parsed["seller"]
    assert "Manufacturer: GreenTea India Private Limited" in parsed["description"]
    assert "https://images-na.ssl-images-amazon.com/images/I/71xyz.jpg" in parsed["image_urls"]

def test_flipkart_parsing_offline():
    html = _read_fixture("flipkart_product.html")
    parsed = parse_with_selectors(html, "flipkart.com")
    
    assert parsed["title"] == "Imported Organic Coffee Beans (250g)"
    assert parsed["price"] == "Rs. 899"
    assert "Premium Brews" in parsed["seller"]
    assert "Country of Origin: Colombia" in parsed["description"]
    assert "https://rukminim1.flixcart.com/image/832/832/coffee.jpeg" in parsed["image_urls"]

@pytest.mark.anyio
@patch("app.services.scraper_service._perform_static_request")
async def test_scrape_product_static_success(mock_request):
    html = _read_fixture("amazon_product.html")
    
    mock_resp = MagicMock()
    mock_resp.text = html
    mock_resp.status_code = 200
    mock_request.return_value = mock_resp
    
    # Run scraper with a mock URL
    res = await scrape_product("https://www.amazon.in/dp/B012345")
    assert res["title"] == "Super Organic Tea 100g Bag"
    assert res["price"] == "Rs. 250.00"

@pytest.mark.anyio
@patch("app.services.scraper_service._perform_static_request")
async def test_scrape_product_blocked(mock_request):
    mock_resp = MagicMock()
    mock_resp.text = "<html><title>Robot Check</title></html>"
    mock_resp.status_code = 503
    mock_request.return_value = mock_resp
    
    with pytest.raises(ScrapeBlockedError):
        await scrape_product("https://www.amazon.in/dp/B012345")
