@echo off
setlocal

echo === 1. Setting up Virtual Environment (Windows) ===

if not exist ".venv" (
    echo Creating .venv...
    python -m venv .venv
)

:: Activate venv
call .venv\Scripts\activate.bat

echo Upgrading pip...
python -m pip install --upgrade pip

echo Installing dependencies...
pip install requests sentence-transformers "transformers<5.0.0" torch Pillow

echo === 2. Running Setup Script ===
python setup_and_run.py

pause

