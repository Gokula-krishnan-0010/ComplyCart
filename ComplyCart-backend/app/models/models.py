from datetime import datetime

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import declarative_base, relationship


Base = declarative_base()


class Seller(Base):
    __tablename__ = "sellers"

    id = Column(String(20), primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    platform = Column(String(100), nullable=True)
    compliance_score = Column(Integer, nullable=True)
    star_rating = Column(Float, nullable=True)
    is_verified = Column(Boolean, default=False)
    product_count = Column(Integer, default=0)
    active_since = Column(String(20), nullable=True)
    total_compliance_checks = Column(Integer, default=0)

    products = relationship("Product", back_populates="seller")


class Product(Base):
    __tablename__ = "products"

    id = Column(String(20), primary_key=True, index=True)
    seller_id = Column(String(20), ForeignKey("sellers.id"), nullable=False)
    title = Column(String(255), nullable=False)
    brand = Column(String(255), nullable=True)
    category = Column(String(100), nullable=True)
    image_url = Column(String(1024), nullable=True)
    mrp = Column(String(50), nullable=True)
    net_quantity = Column(String(50), nullable=True)
    unit = Column(String(20), nullable=True)
    manufacturer = Column(String(255), nullable=True)
    manufacturer_address = Column(Text, nullable=True)
    country_of_origin = Column(String(100), nullable=True)
    consumer_care_email = Column(String(255), nullable=True)
    consumer_care_phone = Column(String(50), nullable=True)
    mfg_date = Column(String(20), nullable=True)
    importer = Column(String(255), nullable=True)
    compliance_score = Column(Integer, nullable=True)
    status = Column(String(50), nullable=True)
    missing_fields = Column(JSONB, nullable=True)
    last_checked_date = Column(String(20), nullable=True)

    seller = relationship("Seller", back_populates="products")


class AnalysisRecord(Base):
    __tablename__ = "analysis_records"

    id = Column(Integer, primary_key=True, index=True)
    url = Column(String(2048), nullable=False)
    normalized_url = Column(String(2048), nullable=True)
    product_name = Column(String(255), nullable=True)
    mrp = Column(String(255), nullable=True)
    net_quantity = Column(String(255), nullable=True)
    manufacturer = Column(String(255), nullable=True)
    manufacturer_address = Column(Text, nullable=True)
    country_of_origin = Column(String(255), nullable=True)
    consumer_care_email = Column(String(255), nullable=True)
    consumer_care_phone = Column(String(255), nullable=True)
    mfg_date = Column(String(255), nullable=True)
    importer = Column(String(255), nullable=True)
    compliance_score = Column(Float, nullable=True)
    status = Column(String(50), nullable=True)
    extraction_method = Column(String(50), nullable=True)
    scraped_via = Column(String(50), nullable=True)
    fields_evaluation = Column(JSONB, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)

