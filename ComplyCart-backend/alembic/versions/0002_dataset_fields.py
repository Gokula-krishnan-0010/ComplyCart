"""add dataset fields to products

Revision ID: 0002_dataset_fields
Revises: 0001_initial_tables
Create Date: 2026-08-04 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


revision = "0002_dataset_fields"
down_revision = "0001_initial_tables"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("products", sa.Column("title", sa.String(length=255), nullable=True))
    op.add_column("products", sa.Column("brand", sa.String(length=255), nullable=True))
    op.add_column("products", sa.Column("category", sa.String(length=100), nullable=True))
    op.add_column("products", sa.Column("mrp", sa.String(length=50), nullable=True))
    op.add_column("products", sa.Column("net_quantity", sa.String(length=50), nullable=True))
    op.add_column("products", sa.Column("unit", sa.String(length=20), nullable=True))
    op.add_column("products", sa.Column("manufacturer", sa.String(length=255), nullable=True))
    op.add_column("products", sa.Column("manufacturer_address", sa.Text(), nullable=True))
    op.add_column("products", sa.Column("country_of_origin", sa.String(length=100), nullable=True))
    op.add_column("products", sa.Column("consumer_care_email", sa.String(length=255), nullable=True))
    op.add_column("products", sa.Column("consumer_care_phone", sa.String(length=50), nullable=True))
    op.add_column("products", sa.Column("mfg_date", sa.String(length=20), nullable=True))
    op.add_column("products", sa.Column("importer", sa.String(length=255), nullable=True))
    op.add_column("products", sa.Column("missing_fields", sa.Text(), nullable=True))


def downgrade():
    op.drop_column("products", "missing_fields")
    op.drop_column("products", "importer")
    op.drop_column("products", "mfg_date")
    op.drop_column("products", "consumer_care_phone")
    op.drop_column("products", "consumer_care_email")
    op.drop_column("products", "country_of_origin")
    op.drop_column("products", "manufacturer_address")
    op.drop_column("products", "manufacturer")
    op.drop_column("products", "unit")
    op.drop_column("products", "net_quantity")
    op.drop_column("products", "mrp")
    op.drop_column("products", "category")
    op.drop_column("products", "brand")
    op.drop_column("products", "title")
