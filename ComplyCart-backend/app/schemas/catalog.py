from typing import List, Optional

from pydantic import BaseModel, Field


class ConsumerCareOut(BaseModel):
    email: Optional[str] = None
    phone: Optional[str] = None


class ProductOut(BaseModel):
    id: str
    seller_id: str
    title: str
    brand: Optional[str] = None
    category: Optional[str] = None
    image_url: Optional[str] = None
    compliance_score: Optional[int] = None
    status: Optional[str] = None
    mrp: Optional[str] = None
    net_quantity: Optional[str] = None
    unit: Optional[str] = None
    manufacturer: Optional[str] = None
    manufacturer_address: Optional[str] = None
    country_of_origin: Optional[str] = None
    consumer_care: Optional[ConsumerCareOut] = None
    mfg_date: Optional[str] = None
    importer: Optional[str] = None
    missing_fields: Optional[List[str]] = None
    last_checked_date: Optional[str] = None


class SellerOut(BaseModel):
    id: str
    name: str
    platform: Optional[str] = None
    compliance_score: Optional[int] = None
    star_rating: Optional[float] = None
    is_verified: bool
    product_count: int
    active_since: Optional[str] = None
    total_compliance_checks: int
    products: List[ProductOut] = Field(default_factory=list)


class ComplianceFieldOut(BaseModel):
    field_name: str
    is_found: bool
    violated_clause: Optional[str] = None
    confidence_score: Optional[float] = None


class ProductComplianceOut(BaseModel):
    product_id: str
    score: int
    status: str
    fields: List[ComplianceFieldOut] = Field(default_factory=list)
