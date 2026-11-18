import os
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, pool
from sqlalchemy.orm import sessionmaker
from sqlalchemy.ext.compiler import compiles
from sqlalchemy.dialects.postgresql import JSONB

from app.main import app
from app.db import get_db
from app.models.models import Base, AnalysisRecord

# Compile JSONB for SQLite in testing
@compiles(JSONB, "sqlite")
def compile_jsonb_sqlite(type_, compiler, **kw):
    return "JSON"

# Set up SQLite test database (in-memory)
SQLALCHEMY_DATABASE_URL = "sqlite://"
engine = create_engine(SQLALCHEMY_DATABASE_URL, poolclass=pool.StaticPool, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def override_get_db():
    try:
        db = TestingSessionLocal()
        yield db
    finally:
        db.close()

app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_db():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    # Clear old data
    db.query(AnalysisRecord).delete()
    db.commit()
    db.close()
    yield
    Base.metadata.drop_all(bind=engine)
    engine.dispose()


def test_analyze_and_cache_history_stats():
    # URL to test (we can use the Amazon Scotch-Brite URL)
    url = "https://www.amazon.in/Scotch-Brite-Plastic-Kitchen-Wiper-Grey/dp/B07DWKC8TB/"
    
    # 1. Test POST /api/v1/analyze/url
    payload = {"url": url, "force_refresh": True}
    response = client.post("/api/v1/analyze/url", json=payload)
    assert response.status_code == 200, f"Failed: {response.text}"
    
    data = response.json()
    assert "product_name" in data
    assert "compliance_score" in data
    assert "status" in data
    assert data["cached"] is False
    assert "extraction_method" in data
    assert "fields" in data
    
    # Ensure fields shape: {name, is_found, note}
    for field in data["fields"]:
        assert "name" in field
        assert "is_found" in field
        assert "note" in field

    # 2. Test cached POST /api/v1/analyze/url (should be fast, cached: True)
    payload_cache = {"url": url, "force_refresh": False}
    response_cache = client.post("/api/v1/analyze/url", json=payload_cache)
    assert response_cache.status_code == 200
    data_cache = response_cache.json()
    assert data_cache["cached"] is True
    assert data_cache["product_name"] == data["product_name"]
    assert len(data_cache["fields"]) == len(data["fields"])

    # 3. Test GET /api/v1/analyses (history)
    response_history = client.get("/api/v1/analyses?limit=5")
    assert response_history.status_code == 200
    history = response_history.json()
    assert len(history) >= 1
    assert history[0]["product_name"] == data["product_name"]
    assert "normalized_url" in history[0]

    # 4. Test GET /api/v1/analyses/stats
    response_stats = client.get("/api/v1/analyses/stats")
    assert response_stats.status_code == 200
    stats = response_stats.json()
    assert stats["total"] >= 1
    assert "compliant" in stats
    assert "non_compliant" in stats
