import json
from datetime import datetime, timezone
from pathlib import Path

from app.db.session import SessionLocal, engine
from app.models.models import Base, Product, Seller


DATASET_PATHS = [
    Path(__file__).resolve().parents[1] / "data" / "seller_dataset.json",
    Path(r"C:\Users\ashfa\Downloads\seller_dataset.json"),
]


def _parse_date(value: str | None):
    if not value:
        return None
    return datetime.strptime(value, "%d/%m/%Y").replace(tzinfo=timezone.utc)


def _load_dataset():
    for dataset_path in DATASET_PATHS:
        if dataset_path.exists():
            with dataset_path.open("r", encoding="utf-8") as handle:
                return json.load(handle)
    raise FileNotFoundError("seller_dataset.json was not found in the backend or Downloads folder")


def seed():
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        dataset = _load_dataset()

        for seller_item in dataset:
            seller = db.query(Seller).filter(Seller.id == seller_item["id"]).first()
            if seller is None:
                seller = Seller(
                    id=seller_item["id"],
                    name=seller_item["name"],
                    platform=seller_item.get("platform"),
                    compliance_score=int(seller_item.get("compliance_score", 0)),
                    star_rating=float(seller_item.get("star_rating", 0)),
                    is_verified=bool(seller_item.get("is_verified", False)),
                    product_count=int(seller_item.get("product_count", 0)),
                    active_since=seller_item.get("active_since"),
                    total_compliance_checks=int(seller_item.get("total_compliance_checks", 0)),
                )
                db.add(seller)
                db.flush()

            for product_item in seller_item.get("products", []):
                existing_product = db.query(Product).filter(Product.id == product_item["id"]).first()
                if existing_product is not None:
                    continue

                consumer_care = product_item.get("consumer_care") or {}
                db.add(
                    Product(
                        id=product_item["id"],
                        seller_id=seller.id,
                        title=product_item["title"],
                        brand=product_item.get("brand"),
                        category=product_item.get("category"),
                        image_url=product_item.get("image_url"),
                        mrp=product_item.get("mrp"),
                        net_quantity=product_item.get("net_quantity"),
                        unit=product_item.get("unit"),
                        manufacturer=product_item.get("manufacturer"),
                        manufacturer_address=product_item.get("manufacturer_address"),
                        country_of_origin=product_item.get("country_of_origin"),
                        consumer_care_email=consumer_care.get("email"),
                        consumer_care_phone=consumer_care.get("phone"),
                        mfg_date=product_item.get("mfg_date"),
                        importer=product_item.get("importer"),
                        compliance_score=int(product_item.get("compliance_score", 0)),
                        status=product_item.get("status"),
                        missing_fields=product_item.get("missing_fields", []),
                        last_checked_date=product_item.get("last_checked_date"),
                    )
                )

        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    seed()
