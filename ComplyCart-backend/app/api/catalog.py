from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db import get_db
from app.models.models import Seller, Product
from app.schemas.catalog import SellerOut, ProductOut, ProductComplianceOut

router = APIRouter(tags=["catalog"])


def _serialize_product(product: Product) -> dict:
    return {
        "id": product.id,
        "seller_id": product.seller_id,
        "title": product.title,
        "brand": product.brand,
        "category": product.category,
        "image_url": product.image_url,
        "compliance_score": product.compliance_score,
        "status": product.status,
        "mrp": product.mrp,
        "net_quantity": product.net_quantity,
        "unit": product.unit,
        "manufacturer": product.manufacturer,
        "manufacturer_address": product.manufacturer_address,
        "country_of_origin": product.country_of_origin,
        "consumer_care": {
            "email": product.consumer_care_email,
            "phone": product.consumer_care_phone,
        },
        "mfg_date": product.mfg_date,
        "importer": product.importer,
        "missing_fields": product.missing_fields or [],
        "last_checked_date": product.last_checked_date,
    }


def _serialize_seller(seller: Seller) -> dict:
    return {
        "id": seller.id,
        "name": seller.name,
        "platform": seller.platform,
        "compliance_score": seller.compliance_score,
        "star_rating": seller.star_rating,
        "is_verified": seller.is_verified,
        "product_count": seller.product_count,
        "active_since": seller.active_since,
        "total_compliance_checks": seller.total_compliance_checks,
        "products": [_serialize_product(product) for product in seller.products],
    }


@router.get("/products", response_model=list[ProductOut])
@router.get("/catalog/products", response_model=list[ProductOut], include_in_schema=False)
def list_products(db: Session = Depends(get_db)):
    products = db.query(Product).order_by(Product.id.asc()).all()
    return [_serialize_product(product) for product in products]


@router.get("/sellers", response_model=list[SellerOut])
@router.get("/catalog/sellers", response_model=list[SellerOut], include_in_schema=False)
def list_sellers(search: str | None = Query(default=None), db: Session = Depends(get_db)):
    sellers_query = db.query(Seller)
    if search:
      normalized = f"%{search.lower()}%"
      sellers_query = sellers_query.filter(
          Seller.name.ilike(normalized) | Seller.platform.ilike(normalized)
      )
    sellers = sellers_query.order_by(Seller.id.asc()).all()
    return [_serialize_seller(seller) for seller in sellers]


@router.get("/sellers/{seller_id}", response_model=SellerOut)
@router.get("/catalog/sellers/{seller_id}", response_model=SellerOut, include_in_schema=False)
def get_seller(seller_id: str, db: Session = Depends(get_db)):
    seller = db.query(Seller).filter(Seller.id == seller_id).first()
    if seller is None:
        raise HTTPException(status_code=404, detail="Seller not found")
    return _serialize_seller(seller)


@router.get("/sellers/{seller_id}/products", response_model=list[ProductOut])
@router.get("/catalog/sellers/{seller_id}/products", response_model=list[ProductOut], include_in_schema=False)
def get_seller_products(seller_id: str, db: Session = Depends(get_db)):
    seller = db.query(Seller).filter(Seller.id == seller_id).first()
    if seller is None:
        raise HTTPException(status_code=404, detail="Seller not found")
    return [_serialize_product(product) for product in seller.products]


@router.get("/products/{product_id}/compliance", response_model=ProductComplianceOut)
@router.get("/catalog/products/{product_id}/compliance", response_model=ProductComplianceOut, include_in_schema=False)
def get_product_compliance(product_id: str, db: Session = Depends(get_db)):
    product = db.query(Product).filter(Product.id == product_id).first()
    if product is None:
        raise HTTPException(status_code=404, detail="Product not found")

    missing_fields = set(product.missing_fields or [])
    required_fields = [
        "MRP",
        "Net Quantity",
        "Manufacturer",
        "Manufacturer Address",
        "Country of Origin",
        "Consumer Care Details",
        "Date of Manufacture",
        "Importer Details",
    ]

    fields = []
    for field_name in required_fields:
        is_found = field_name not in missing_fields
        fields.append(
            {
                "field_name": field_name,
                "is_found": is_found,
                "violated_clause": None if is_found else f"Missing {field_name}",
                "confidence_score": float(product.compliance_score or 0) if is_found else float(max((product.compliance_score or 0) - 20, 0)),
            }
        )

    return {
        "product_id": product.id,
        "score": int(product.compliance_score or 0),
        "status": product.status or "Unknown",
        "fields": fields,
    }
