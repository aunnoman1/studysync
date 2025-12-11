#!/bin/bash

# Exit on error
set -e

echo "=== 1. Setting up Virtual Environment (Linux/Mac) ==="

if [ ! -d ".venv" ]; then
    echo "Creating .venv..."
    python3.12 -m venv .venv
fi

# Activate venv
source .venv/bin/activate

echo "Upgrading pip..."
pip install --upgrade pip

echo "Installing dependencies..."
# Install standard requests for the script itself + model downloaders
pip install requests sentence-transformers transformers torch

echo "=== 2. Running Setup Script ==="
python3 setup_and_run.py

