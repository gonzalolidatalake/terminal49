# Development Environment Setup Guide

This guide will help you set up your local development environment for the Terminal49 Webhook Infrastructure project.

## Prerequisites

- **Python 3.11+** installed
- **Git** installed
- **gcloud CLI** installed and configured
- **Terraform** 1.5+ installed (for infrastructure deployment)
- **GCP Project Access**: `li-customer-datalake`
- **Supabase Project Access**: `srordjhkcvyfyvepzrzp`

## Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd terminal49-webhook-infrastructure

# 2. Run the setup script
./scripts/setup_dev_env.sh

# 3. Activate virtual environment
source .venv/bin/activate  # On Unix/macOS
# or
.venv\Scripts\activate  # On Windows

# 4. Verify installation
python --version  # Should be 3.11+
pytest --version
```

## Detailed Setup Steps

### 1. Python Environment Setup

#### Using pyenv (Recommended)

```bash
# Install pyenv (if not already installed)
curl https://pyenv.run | bash

# Install Python 3.11.7
pyenv install 3.11.7
pyenv local 3.11.7

# Verify Python version
python --version  # Should output: Python 3.11.7
```

#### Using system Python

```bash
# Verify Python version
python3 --version  # Must be 3.11 or higher

# Create alias if needed
alias python=python3
```

### 2. Virtual Environment Setup

```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment
source .venv/bin/activate  # Unix/macOS
# or
.venv\Scripts\activate  # Windows

# Upgrade pip
pip install --upgrade pip setuptools wheel
```

### 3. Install Dependencies

```bash
# Install all dependencies
pip install -r requirements.txt

# Verify installation
pip list
```

### 4. Environment Variables Configuration

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your actual values
nano .env  # or use your preferred editor
```

**Required values to configure:**
- `TERMINAL49_API_KEY` - Get from Terminal49 dashboard
- `TERMINAL49_WEBHOOK_SECRET` - Get from Terminal49 webhook configuration
- `SUPABASE_SERVICE_ROLE_KEY` - Get from Supabase project settings
- `SUPABASE_DB_PASSWORD` - Get from Supabase database settings

### 5. GCP Authentication

```bash
# Login to GCP
gcloud auth login

# Set project
gcloud config set project li-customer-datalake

# Create application default credentials
gcloud auth application-default login

# Verify access
gcloud projects describe li-customer-datalake
```

### 6. Pre-commit Hooks Setup

```bash
# Install pre-commit hooks
pre-commit install

# Run hooks on all files (optional)
pre-commit run --all-files
```

### 7. Database Setup

#### Supabase Schema Deployment

```bash
# Connect to Supabase and run schema
psql "postgresql://postgres:[PASSWORD]@db.srordjhkcvyfyvepzrzp.supabase.co:5432/postgres" \
  -f infrastructure/database/supabase_schema.sql

# Or use Supabase CLI
supabase db push
```

#### BigQuery Dataset Creation

```bash
# Create BigQuery dataset
gcloud bigquery datasets create terminal49_raw_events \
  --project=li-customer-datalake \
  --location=us-central1 \
  --description="Terminal49 webhook raw events archive"

# Create tables
bq query --use_legacy_sql=false < infrastructure/database/bigquery_schema.sql
```

### 8. Verify Setup

```bash
# Run tests
pytest tests/ -v

# Check code formatting
black --check .

# Run linters
flake8 .
mypy .

# Check imports
isort --check-only .
```

## Project Structure

```
terminal49-webhook-infrastructure/
├── functions/                    # Cloud Functions code
│   ├── webhook_receiver/        # Webhook receiver function
│   └── event_processor/         # Event processor function
├── shared/                      # Shared utilities and libraries
│   ├── database/               # Database connection utilities
│   ├── logging/                # Logging configuration
│   └── validators/             # Validation utilities
├── infrastructure/              # Infrastructure as Code
│   ├── terraform/              # Terraform modules
│   ├── gcp/                    # GCP setup documentation
│   └── database/               # Database schemas
├── tests/                       # Test suite
│   ├── unit/                   # Unit tests
│   └── integration/            # Integration tests
├── scripts/                     # Utility scripts
├── docs/                        # Documentation
├── .github/                     # GitHub Actions workflows
├── requirements.txt             # Python dependencies
├── pyproject.toml              # Python project configuration
├── .env.example                # Environment variables template
└── README.md                   # Project README
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

- Write code following PEP 8 style guide
- Add type hints to all functions
- Write docstrings for all public functions
- Add unit tests for new functionality

### 3. Run Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=functions --cov=shared --cov-report=html

# Run specific test file
pytest tests/unit/test_webhook_validator.py -v

# Run tests with specific marker
pytest -m unit  # Only unit tests
pytest -m integration  # Only integration tests
```

### 4. Format and Lint

```bash
# Format code with Black
black .

# Sort imports
isort .

# Run flake8
flake8 .

# Run mypy
mypy .

# Or run all pre-commit hooks
pre-commit run --all-files
```

### 5. Commit Changes

```bash
git add .
git commit -m "feat: add webhook signature validation"

# Pre-commit hooks will run automatically
```

### 6. Push and Create PR

```bash
git push origin feature/your-feature-name

# Create Pull Request on GitHub
```

## Local Testing

### Test Webhook Receiver Locally

```bash
# Start local Functions Framework
cd functions/webhook_receiver
functions-framework --target=webhook_receiver --port=8080

# In another terminal, send test webhook
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -H "X-T49-Webhook-Signature: test-signature" \
  -d @tests/fixtures/sample_webhook.json
```

### Test Event Processor Locally

```bash
# Start local Functions Framework
cd functions/event_processor
functions-framework --target=process_webhook_event --port=8081 --signature-type=event

# Trigger with test Pub/Sub message
# (See tests/integration/test_event_processor.py for examples)
```

### Run Integration Tests

```bash
# Set up test environment
export ENVIRONMENT=test
export USE_TERMINAL49_SANDBOX=true

# Run integration tests
pytest tests/integration/ -v

# Run with GCP services (requires credentials)
pytest tests/integration/ -v -m requires_gcp
```

## Troubleshooting

### Issue: Python version mismatch

```bash
# Check Python version
python --version

# If wrong version, use pyenv
pyenv local 3.11.7
```

### Issue: Import errors

```bash
# Reinstall dependencies
pip install -r requirements.txt --force-reinstall

# Check PYTHONPATH
echo $PYTHONPATH
export PYTHONPATH="${PYTHONPATH}:$(pwd)"
```

### Issue: GCP authentication errors

```bash
# Re-authenticate
gcloud auth application-default login

# Check credentials
gcloud auth list

# Verify project access
gcloud projects get-iam-policy li-customer-datalake
```

### Issue: Database connection errors

```bash
# Test Supabase connection
psql "postgresql://postgres:[PASSWORD]@db.srordjhkcvyfyvepzrzp.supabase.co:5432/postgres" -c "SELECT version();"

# Test BigQuery connection
bq ls --project_id=li-customer-datalake
```

### Issue: Pre-commit hooks failing

```bash
# Update pre-commit hooks
pre-commit autoupdate

# Clear cache and reinstall
pre-commit clean
pre-commit install
```

## IDE Configuration

### VS Code

Recommended extensions:
- Python (Microsoft)
- Pylance
- Black Formatter
- isort
- Terraform
- YAML

Settings (`.vscode/settings.json`):
```json
{
  "python.defaultInterpreterPath": ".venv/bin/python",
  "python.formatting.provider": "black",
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "python.linting.mypyEnabled": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  }
}
```

### PyCharm

1. Set Python interpreter: Settings → Project → Python Interpreter → Add → Existing environment → `.venv/bin/python`
2. Enable Black: Settings → Tools → Black → Enable
3. Enable mypy: Settings → Tools → External Tools → Add mypy
4. Configure pytest: Settings → Tools → Python Integrated Tools → Testing → pytest

## Useful Commands

```bash
# Update dependencies
pip install --upgrade -r requirements.txt

# Generate requirements from environment
pip freeze > requirements.txt

# Run specific test with verbose output
pytest tests/unit/test_webhook_validator.py::test_valid_signature -vv

# Check test coverage
pytest --cov=functions --cov-report=term-missing

# Format single file
black functions/webhook_receiver/main.py

# Check types for single file
mypy functions/webhook_receiver/main.py

# Clean Python cache
find . -type d -name "__pycache__" -exec rm -r {} +
find . -type f -name "*.pyc" -delete

# View logs from Cloud Functions
gcloud functions logs read terminal49-webhook-receiver --limit=50
```

## Next Steps

After completing the development environment setup:

1. Review [`DEVELOPMENT_PLAN.md`](DEVELOPMENT_PLAN.md) for implementation phases
2. Read [`infrastructure/gcp/PROJECT_SETUP.md`](infrastructure/gcp/PROJECT_SETUP.md) for GCP configuration
3. Review [`infrastructure/database/DATABASE_SELECTION.md`](infrastructure/database/DATABASE_SELECTION.md) for database architecture
4. Start implementing Phase 2: Core Webhook Infrastructure

## Getting Help

- **Documentation**: See [`docs/`](docs/) directory
- **Issues**: Create an issue on GitHub
- **Team Chat**: [Your team communication channel]

## Resources

- [Terminal49 API Documentation](https://docs.terminal49.com)
- [Google Cloud Functions Documentation](https://cloud.google.com/functions/docs)
- [Supabase Documentation](https://supabase.com/docs)
- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Python Best Practices](https://docs.python-guide.org/)
