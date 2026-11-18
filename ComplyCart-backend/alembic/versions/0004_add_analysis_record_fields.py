"""add analysis record fields

Revision ID: 0004_add_analysis_record_fields
Revises: 0003_rebuild_catalog
Create Date: 2026-08-09 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "0004_add_analysis_record_fields"
down_revision = "0003_rebuild_catalog"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("analysis_records", sa.Column("normalized_url", sa.String(length=2048), nullable=True))
    op.add_column("analysis_records", sa.Column("mrp", sa.String(length=255), nullable=True))
    op.add_column("analysis_records", sa.Column("net_quantity", sa.String(length=255), nullable=True))
    op.add_column("analysis_records", sa.Column("manufacturer", sa.String(length=255), nullable=True))
    op.add_column("analysis_records", sa.Column("manufacturer_address", sa.Text(), nullable=True))
    op.add_column("analysis_records", sa.Column("country_of_origin", sa.String(length=255), nullable=True))
    op.add_column("analysis_records", sa.Column("consumer_care_email", sa.String(length=255), nullable=True))
    op.add_column("analysis_records", sa.Column("consumer_care_phone", sa.String(length=255), nullable=True))
    op.add_column("analysis_records", sa.Column("mfg_date", sa.String(length=255), nullable=True))
    op.add_column("analysis_records", sa.Column("importer", sa.String(length=255), nullable=True))
    op.add_column("analysis_records", sa.Column("extraction_method", sa.String(length=50), nullable=True))
    op.add_column("analysis_records", sa.Column("scraped_via", sa.String(length=50), nullable=True))
    op.add_column("analysis_records", sa.Column("fields_evaluation", postgresql.JSONB(astext_type=sa.Text()), nullable=True))


def downgrade():
    op.drop_column("analysis_records", "fields_evaluation")
    op.drop_column("analysis_records", "scraped_via")
    op.drop_column("analysis_records", "extraction_method")
    op.drop_column("analysis_records", "importer")
    op.drop_column("analysis_records", "mfg_date")
    op.drop_column("analysis_records", "consumer_care_phone")
    op.drop_column("analysis_records", "consumer_care_email")
    op.drop_column("analysis_records", "country_of_origin")
    op.drop_column("analysis_records", "manufacturer_address")
    op.drop_column("analysis_records", "manufacturer")
    op.drop_column("analysis_records", "net_quantity")
    op.drop_column("analysis_records", "mrp")
    op.drop_column("analysis_records", "normalized_url")
