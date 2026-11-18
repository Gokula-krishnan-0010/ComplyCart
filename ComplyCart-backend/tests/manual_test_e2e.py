import asyncio
import os
import sys
from dotenv import load_dotenv

# Load .env variables
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"))

# Ensure the root project directory is in the path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.dialects.postgresql import JSONB

from app.models.models import Base, AnalysisRecord
from app.services.analysis_service import analyze_product_url

@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"

# Default live URL provided by the user
DEFAULT_LIVE_URL = (
    "https://www.amazon.in/Scotch-Brite-Plastic-Kitchen-Wiper-Grey/dp/B07DWKC8TB/"
    "?_encoding=UTF8&pd_rd_w=4y1iT&content-id=amzn1.sym.60882f6c-fec5-45e7-9f67-5e56ff8c8c8f"
    "&pf_rd_p=60882f6c-fec5-45e7-9f67-5e56ff8c8c8f&pf_rd_r=44CA57TK8DGP9SZG7DPQ&pd_rd_wg=rEnCP"
    "&pd_rd_r=38532b4a-0ba5-4295-9675-7fc7fd6b6628&ref_=pd_hp_d_atf_dealz_mlc&th=1"
)

async def run_manual_e2e():
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except AttributeError:
        pass
        
    # If a URL is passed as argument, use it; otherwise use the default live URL
    target_url = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_LIVE_URL
    
    print("--- Starting Live Product E2E Validation Checkpoint ---")
    print(f"Target URL: {target_url}")
    
    # Set up in-memory SQLite DB
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(bind=engine)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = TestingSessionLocal()
    
    def safe_print(text: str):
        print(str(text).replace('\u20b9', 'Rs.'))

    try:
        result = await analyze_product_url(db, target_url, force_refresh=True)
        
        safe_print("\n=== ANALYSIS RESULT ===")
        safe_print(f"Normalized URL:    {result['url']}")
        safe_print(f"Scraped Via:       {result.get('scraped_via')}")
        
        raw_scrape = result.get("raw_scrape", {})
        safe_print("\n--- Raw Scraped Data ---")
        safe_print(f"Raw Title:         {raw_scrape.get('title')}")
        safe_print(f"Raw Price:         {raw_scrape.get('price')}")
        safe_print(f"Raw Seller:        {raw_scrape.get('seller')}")
        
        extracted = result.get("extracted_fields", {})
        safe_print("\n--- Extracted Compliance Fields ---")
        for k, v in extracted.items():
            if k != "extraction_method":
                safe_print(f"  {k}: {v}")
                
        method = result.get("extraction_method")
        safe_print(f"\nExtraction Method: {method}")
        if method == "mock":
            # Determine reason
            if not os.environ.get("GEMINI_API_KEY"):
                safe_print("  Reason for Mock Fallback: GEMINI_API_KEY environment variable is missing.")
            else:
                safe_print("  Reason for Mock Fallback: API Key was configured but an extraction error occurred.")
                
        safe_print("\n--- Compliance Result ---")
        safe_print(f"Score:             {result['compliance_score']}")
        safe_print(f"Status:            {result['status']}")
        safe_print("Fields Evaluation:")
        for f in result.get("fields", []):
            status = "FOUND" if f["is_found"] else "MISSING"
            safe_print(f"  - {f['field_name']}: {status} (Clause: {f.get('violated_clause')})")
            
        # Query DB directly to verify
        db_records = db.query(AnalysisRecord).all()
        safe_print("\n=== VERIFYING DATABASE RECORD ===")
        safe_print(f"Total records in DB: {len(db_records)}")
        if db_records:
            rec = db_records[-1]
            safe_print(f"ID:                     {rec.id}")
            safe_print(f"URL:                    {rec.url}")
            safe_print(f"Normalized URL:         {rec.normalized_url}")
            safe_print(f"Product Name:           {rec.product_name}")
            safe_print(f"MRP:                    {rec.mrp}")
            safe_print(f"Net Qty:                {rec.net_quantity}")
            safe_print(f"Manufacturer:           {rec.manufacturer}")
            safe_print(f"Manufacturer Address:   {rec.manufacturer_address}")
            safe_print(f"Country of Origin:      {rec.country_of_origin}")
            safe_print(f"Consumer Care Email:    {rec.consumer_care_email}")
            safe_print(f"Consumer Care Phone:    {rec.consumer_care_phone}")
            safe_print(f"Mfg Date:               {rec.mfg_date}")
            safe_print(f"Importer:               {rec.importer}")
            safe_print(f"Compliance Score:       {rec.compliance_score}")
            safe_print(f"Status:                 {rec.status}")
            safe_print(f"Extraction Method:      {rec.extraction_method}")
            safe_print(f"Scraped Via:            {rec.scraped_via}")
            safe_print(f"Fields Evaluation (JSON): {rec.fields_evaluation}")
            
    except Exception as e:
        safe_print(f"\nE2E Pipeline execution failed: {str(e)}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()
        safe_print("\n--- Live E2E Checkpoint Completed ---")

if __name__ == "__main__":
    asyncio.run(run_manual_e2e())
