"""rebuild seller and product schema

Revision ID: 0003_rebuild_catalog
Revises: 0002_dataset_fields
Create Date: 2026-08-04 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0003_rebuild_catalog"
down_revision = "0002_dataset_fields"
branch_labels = None
depends_on = None


def upgrade():
    op.drop_table("compliance_fields")
    op.drop_table("products")
    op.drop_table("sellers")

    op.create_table(
        "sellers",
        sa.Column("id", sa.String(length=20), primary_key=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("platform", sa.String(length=100), nullable=True),
        sa.Column("compliance_score", sa.Integer(), nullable=True),
        sa.Column("star_rating", sa.Float(), nullable=True),
        sa.Column("is_verified", sa.Boolean(), nullable=True),
        sa.Column("product_count", sa.Integer(), nullable=True),
        sa.Column("active_since", sa.String(length=20), nullable=True),
        sa.Column("total_compliance_checks", sa.Integer(), nullable=True),
    )

    op.create_table(
        "products",
        sa.Column("id", sa.String(length=20), primary_key=True),
        sa.Column("seller_id", sa.String(length=20), sa.ForeignKey("sellers.id"), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("brand", sa.String(length=255), nullable=True),
        sa.Column("category", sa.String(length=100), nullable=True),
        sa.Column("image_url", sa.String(length=1024), nullable=True),
        sa.Column("mrp", sa.String(length=50), nullable=True),
        sa.Column("net_quantity", sa.String(length=50), nullable=True),
        sa.Column("unit", sa.String(length=20), nullable=True),
        sa.Column("manufacturer", sa.String(length=255), nullable=True),
        sa.Column("manufacturer_address", sa.Text(), nullable=True),
        sa.Column("country_of_origin", sa.String(length=100), nullable=True),
        sa.Column("consumer_care_email", sa.String(length=255), nullable=True),
        sa.Column("consumer_care_phone", sa.String(length=50), nullable=True),
        sa.Column("mfg_date", sa.String(length=20), nullable=True),
        sa.Column("importer", sa.String(length=255), nullable=True),
        sa.Column("compliance_score", sa.Integer(), nullable=True),
        sa.Column("status", sa.String(length=50), nullable=True),
        sa.Column("missing_fields", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("last_checked_date", sa.String(length=20), nullable=True),
    )


def downgrade():
    op.drop_table("products")
    op.drop_table("sellers")

    op.create_table(
        "sellers",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("platform", sa.String(length=100), nullable=True),
        sa.Column("compliance_score", sa.Float(), nullable=True),
        sa.Column("is_verified", sa.Boolean(), nullable=True),
        sa.Column("product_count", sa.Integer(), nullable=True),
        sa.Column("joined_date", sa.DateTime(), nullable=True),
    )

    op.create_table(
        "products",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("seller_id", sa.Integer(), sa.ForeignKey("sellers.id"), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("image_url", sa.String(length=1024), nullable=True),
        sa.Column("compliance_score", sa.Float(), nullable=True),
        sa.Column("status", sa.String(length=50), nullable=True),
        sa.Column("last_checked_date", sa.DateTime(), nullable=True),
        sa.Column("title", sa.String(length=255), nullable=True),
        sa.Column("brand", sa.String(length=255), nullable=True),
        sa.Column("category", sa.String(length=100), nullable=True),
        sa.Column("mrp", sa.String(length=50), nullable=True),
        sa.Column("net_quantity", sa.String(length=50), nullable=True),
        sa.Column("unit", sa.String(length=20), nullable=True),
        sa.Column("manufacturer", sa.String(length=255), nullable=True),
        sa.Column("manufacturer_address", sa.Text(), nullable=True),
        sa.Column("country_of_origin", sa.String(length=100), nullable=True),
        sa.Column("consumer_care_email", sa.String(length=255), nullable=True),
        sa.Column("consumer_care_phone", sa.String(length=50), nullable=True),
        sa.Column("mfg_date", sa.String(length=20), nullable=True),
        sa.Column("importer", sa.String(length=255), nullable=True),
        sa.Column("missing_fields", sa.Text(), nullable=True),
    )
