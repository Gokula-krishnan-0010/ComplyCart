"""initial tables

Revision ID: 0001_initial_tables
Revises: 
Create Date: 2026-07-25 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '0001_initial_tables'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        'sellers',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('platform', sa.String(length=100), nullable=True),
        sa.Column('compliance_score', sa.Float(), nullable=True),
        sa.Column('is_verified', sa.Boolean(), nullable=True),
        sa.Column('product_count', sa.Integer(), nullable=True),
        sa.Column('joined_date', sa.DateTime(), nullable=True),
    )

    op.create_table(
        'products',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('seller_id', sa.Integer(), sa.ForeignKey('sellers.id'), nullable=False),
        sa.Column('name', sa.String(length=255), nullable=False),
        sa.Column('image_url', sa.String(length=1024), nullable=True),
        sa.Column('compliance_score', sa.Float(), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=True),
        sa.Column('last_checked_date', sa.DateTime(), nullable=True),
    )

    op.create_table(
        'analysis_records',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('url', sa.String(length=2048), nullable=False),
        sa.Column('product_name', sa.String(length=255), nullable=True),
        sa.Column('compliance_score', sa.Float(), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=True),
        sa.Column('timestamp', sa.DateTime(), nullable=True),
    )

    op.create_table(
        'compliance_fields',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('analysis_id', sa.Integer(), sa.ForeignKey('analysis_records.id'), nullable=False),
        sa.Column('field_name', sa.String(length=255), nullable=False),
        sa.Column('is_found', sa.Boolean(), nullable=True),
        sa.Column('violated_clause', sa.Text(), nullable=True),
        sa.Column('confidence_score', sa.Float(), nullable=True),
    )


def downgrade():
    op.drop_table('compliance_fields')
    op.drop_table('analysis_records')
    op.drop_table('products')
    op.drop_table('sellers')
