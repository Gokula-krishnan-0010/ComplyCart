from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings

# Use sync SQLAlchemy engine for Alembic compatibility
DATABASE_URL = settings.database_url or "postgresql+psycopg2://complycart:complycart@localhost:5432/complycart"

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# For convenience in scripts
def get_engine():
    return engine
