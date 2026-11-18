# ComplyCart Backend

A FastAPI-based REST API service that powers the compliance verification engine, databases, and reporting systems for ComplyCart.

---

## Technical Stack

- **Framework**: FastAPI
- **Database ORM**: SQLAlchemy
- **Migration Tool**: Alembic
- **Database**: PostgreSQL (containerized via Docker Compose)
- **Settings Management**: Pydantic Settings
- **Validation**: Pydantic v2

---

## Project Structure

```text
app/
├── api/          # Route handlers (catalog, health, etc.)
├── core/         # Configuration, database setup, and security settings
├── db/           # Database sessions, base models, and seed utilities
├── models/       # SQLAlchemy database models (Seller, Product, etc.)
├── schemas/      # Pydantic data transfer schemas for validation
└── services/     # Core compliance scanning and business logic
```

---

## Configuration

Settings and secrets are managed via environment variables.

1. Copy the example environment template:
   ```bash
   cp .env.example .env
   ```
2. Open `.env` and fill in the necessary secrets and database URLs.

---

## Installation & Running

### 1. Prerequisites

- Python 3.10+
- Docker & Docker Compose

### 2. Install Dependencies

It is recommended to run the project in a virtual environment:

```bash
# Create a virtual environment
python -m venv .venv

# Activate the virtual environment
# On Windows:
.venv\Scripts\activate
# On Linux/macOS:
source .venv/bin/activate

# Install requirements
pip install -r requirements.txt
```

### 3. Setup Database & Migrations

Start the PostgreSQL service using Docker Compose:

```bash
docker-compose up -d
```

Apply database migrations using Alembic:

```bash
alembic upgrade head
```

### 4. Seed Database (Optional)

To seed the database with mock seller and compliance catalog data:

```bash
python -m app.db.seed
```

### 5. Start Development Server

Run the FastAPI application with Uvicorn auto-reload enabled:

```bash
uvicorn app.main:app --reload
```

The API will be available locally at `http://127.0.0.1:8000`. You can access the interactive API docs at `http://127.0.0.1:8000/docs`.

---

## Playwright & Web Scraping

### Playwright Headless Setup
To support dynamic Javascript-rendered page fallback scraping, ensure you install Playwright's Chromium browser binary:
```bash
playwright install chromium
```

### Scraping Terms of Service & Limitations
> [!WARNING]
> Web scraping Amazon, Flipkart, and other commercial platforms may violate their Terms of Service and is subject to automated CAPTCHAs, IP blocking, or restrictions. This rule-based scraping pipeline is intended for local development, academic, and evaluation purposes only. For production deployments, it is highly recommended to migrate to official affiliate/partner APIs (such as the Amazon Product Advertising API and Flipkart Affiliate API).