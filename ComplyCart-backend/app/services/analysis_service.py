import re
from datetime import datetime, timedelta
from urllib.parse import urlparse, urlunparse, parse_qsl, urlencode
from typing import Dict, Any
from sqlalchemy.orm import Session

from app.models.models import AnalysisRecord
from app.services.scraper_service import scrape_product
from app.services.field_extraction_service import extract_compliance_fields
from app.services.rule_engine import validate_compliance

def normalize_product_url(url: str) -> str:
    """
    Normalizes URLs to ensure query parameters and tracking variables don't duplicate cache entries.
    For Amazon, canonicalizes to /dp/ASIN.
    """
    parsed = urlparse(url)
    scheme = parsed.scheme.lower()
    netloc = parsed.netloc.lower()
    path = parsed.path
    
    # Strip tracking parameters and canonicalize Amazon paths
    if "amazon" in netloc:
        asin_match = re.search(r'/(?:dp|gp/product)/([A-Z0-9]{10})', path, re.IGNORECASE)
        if asin_match:
            path = f"/dp/{asin_match.group(1)}"
        query_str = ""
    elif "flipkart" in netloc:
        query_str = ""
    else:
        q_params = parse_qsl(parsed.query)
        filtered = []
        tracking_params = {"ref", "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "ref_", "th"}
        for k, v in q_params:
            if k.lower() not in tracking_params:
                filtered.append((k, v))
        query_str = urlencode(filtered) if filtered else ""
        
    return urlunparse((scheme, netloc, path, parsed.params, query_str, parsed.fragment))

async def analyze_product_url(db: Session, url: str, force_refresh: bool = False) -> Dict[str, Any]:
    """
    Orchestrates: normalize URL -> Check 24hr cache -> Scrape -> Extract -> Validate compliance -> Save to DB.
    """
    normalized_url = normalize_product_url(url)
    
    if not force_refresh:
        # Check cache
        time_threshold = datetime.utcnow() - timedelta(hours=24)
        cached_record = (
            db.query(AnalysisRecord)
            .filter(
                (AnalysisRecord.normalized_url == normalized_url) | (AnalysisRecord.url == normalized_url),
                AnalysisRecord.timestamp >= time_threshold
            )
            .order_by(AnalysisRecord.timestamp.desc())
            .first()
        )
        if cached_record:
            return {
                "url": cached_record.normalized_url or cached_record.url,
                "product_name": cached_record.product_name,
                "compliance_score": cached_record.compliance_score,
                "status": cached_record.status,
                "cached": True,
                "fields": cached_record.fields_evaluation or [],
                "timestamp": cached_record.timestamp.isoformat(),
                "extraction_method": cached_record.extraction_method,
                "scraped_via": cached_record.scraped_via,
                "extracted_fields": {
                    "mrp": cached_record.mrp,
                    "net_quantity": cached_record.net_quantity,
                    "manufacturer": cached_record.manufacturer,
                    "manufacturer_address": cached_record.manufacturer_address,
                    "country_of_origin": cached_record.country_of_origin,
                    "consumer_care_email": cached_record.consumer_care_email,
                    "consumer_care_phone": cached_record.consumer_care_phone,
                    "mfg_date": cached_record.mfg_date,
                    "importer": cached_record.importer,
                }
            }
            
    # Scraping
    raw_scrape = await scrape_product(url)
    
    # Field extraction
    extracted_fields = extract_compliance_fields(raw_scrape)
    
    # Rule engine validation
    compliance_res = validate_compliance(extracted_fields)
    
    # Save analysis record to DB
    new_record = AnalysisRecord(
        url=normalized_url,
        normalized_url=normalized_url,
        product_name=raw_scrape.get("title"),
        mrp=extracted_fields.get("mrp"),
        net_quantity=extracted_fields.get("net_quantity"),
        manufacturer=extracted_fields.get("manufacturer"),
        manufacturer_address=extracted_fields.get("manufacturer_address"),
        country_of_origin=extracted_fields.get("country_of_origin"),
        consumer_care_email=extracted_fields.get("consumer_care_email"),
        consumer_care_phone=extracted_fields.get("consumer_care_phone"),
        mfg_date=extracted_fields.get("mfg_date"),
        importer=extracted_fields.get("importer"),
        compliance_score=float(compliance_res.compliance_score),
        status=compliance_res.status,
        extraction_method=extracted_fields.get("extraction_method", "unknown"),
        scraped_via=raw_scrape.get("scraped_via"),
        fields_evaluation=[f.model_dump() for f in compliance_res.fields],
        timestamp=datetime.utcnow()
    )
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    
    return {
        "url": normalized_url,
        "product_name": raw_scrape.get("title"),
        "compliance_score": compliance_res.compliance_score,
        "status": compliance_res.status,
        "cached": False,
        "fields": [f.model_dump() for f in compliance_res.fields],
        "timestamp": new_record.timestamp.isoformat(),
        "extraction_method": extracted_fields.get("extraction_method", "unknown"),
        "scraped_via": raw_scrape.get("scraped_via"),
        "raw_scrape": {
            "title": raw_scrape.get("title"),
            "price": raw_scrape.get("price"),
            "seller": raw_scrape.get("seller")
        },
        "extracted_fields": extracted_fields
    }
