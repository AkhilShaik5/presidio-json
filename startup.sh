#!/bin/bash
set -e # Exit on error
echo "Starting startup script..."

# Set environment variables
export PYTHONUNBUFFERED=1
export PORT=8000
export WORKERS=2

# Set the site directory
SITE_DIR="/home/site/wwwroot"
cd $SITE_DIR || exit 1

# Create directories
mkdir -p /home/LogFiles templates

# Install dependencies in correct order
echo "Installing core packages..."
python -m pip install --no-cache-dir pip setuptools wheel --upgrade

echo "Installing numpy..."
python -m pip install --no-cache-dir numpy==1.23.5

echo "Installing base packages..."
python -m pip install --no-cache-dir \
    flask==2.0.1 \
    werkzeug==2.0.3 \
    python-dotenv==0.19.0 \
    gunicorn==20.1.0 \
    packaging==23.1 \
    requests==2.31.0

echo "Installing Presidio packages..."
python -m pip install --no-cache-dir \
    presidio-analyzer==2.2.32 \
    presidio-anonymizer==2.2.32

# Start the application
echo "Starting application..."
exec gunicorn --bind=0.0.0.0:$PORT --workers=$WORKERS app:app