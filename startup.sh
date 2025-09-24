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

# Set working directory
echo "Changing to directory: $SITE_DIR"
cd $SITE_DIR

# List directory contents for debugging
echo "Current directory contents:"
ls -la

# Check if requirements.txt exists
if [ ! -f requirements.txt ]; then
    echo "Warning: requirements.txt not found in current directory"
    echo "Searching in parent directories..."
    REQUIREMENTS_FILE=$(find / -name requirements.txt -type f 2>/dev/null | head -n 1)
    if [ -z "$REQUIREMENTS_FILE" ]; then
        echo "Error: requirements.txt not found anywhere"
        exit 1
    else
        echo "Found requirements.txt at: $REQUIREMENTS_FILE"
        cp "$REQUIREMENTS_FILE" ./requirements.txt
    fi
fi

# Check if app.py exists
if [ ! -f app.py ]; then
    echo "Warning: app.py not found in current directory"
    echo "Searching in parent directories..."
    APP_FILE=$(find / -name app.py -type f 2>/dev/null | head -n 1)
    if [ -z "$APP_FILE" ]; then
        echo "Error: app.py not found anywhere"
        exit 1
    else
        echo "Found app.py at: $APP_FILE"
        cp "$APP_FILE" ./app.py
    fi
fi

# Activate virtual environment if it exists
if [ -d "antenv" ]; then
    echo "Activating virtual environment: antenv"
    source antenv/bin/activate
fi

# Install dependencies
echo "Installing dependencies..."
python -m pip install --upgrade pip setuptools wheel

# Clean pip cache
echo "Cleaning pip cache..."
pip cache purge

# Uninstall existing numpy if present
echo "Removing existing numpy installation..."
pip uninstall -y numpy

# Install numpy with specific version
echo "Installing numpy..."
pip install --no-cache-dir numpy==1.23.5

# Verify numpy installation
echo "Verifying numpy installation..."
python -c "import numpy; print('Numpy version:', numpy.__version__)" || {
    echo "Failed to import numpy, trying alternative installation..."
    pip uninstall -y numpy
    pip install --no-cache-dir numpy==1.21.6
    python -c "import numpy; print('Numpy version:', numpy.__version__)"
}

# Install other dependencies
echo "Installing other dependencies..."
pip install --no-cache-dir -r requirements.txt

# Install spacy and its model
echo "Installing spacy and model..."
python -m pip install --no-cache-dir spacy==3.7.5
python -m spacy download en_core_web_md

# Create templates directory if it doesn't exist
mkdir -p templates

# Start the application
echo "Starting application..."
pip install -r requirements.txt
exec gunicorn --bind=0.0.0.0:$PORT --workers=$WORKERS app:app