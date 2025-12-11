import subprocess
import sys
import os
import time
import shutil

def run_command(command, cwd=None, shell=True):
    """Run a shell command and print output in real-time."""
    print(f"--> Running: {command}")
    try:
        process = subprocess.Popen(
            command, 
            cwd=cwd, 
            shell=shell, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.STDOUT,
            text=True
        )
        
        # Print output in real-time
        for line in process.stdout:
            print(line, end='')
            
        process.wait()
        
        if process.returncode != 0:
            print(f"Error: Command failed with exit code {process.returncode}")
            sys.exit(process.returncode)
            
    except Exception as e:
        print(f"Failed to execute command: {e}")
        sys.exit(1)

def get_venv_python():
    """Create a virtual environment if not exists and return the python executable path."""
    venv_dir = os.path.join(os.getcwd(), ".venv")
    
    # Determine python executable path in venv
    if sys.platform == "win32":
        python_executable = os.path.join(venv_dir, "Scripts", "python.exe")
    else:
        python_executable = os.path.join(venv_dir, "bin", "python")

    # Create venv if it doesn't exist
    if not os.path.exists(venv_dir):
        print(f"Creating virtual environment at {venv_dir}...")
        subprocess.check_call([sys.executable, "-m", "venv", venv_dir])
        
        # Upgrade pip immediately
        print("Upgrading pip in virtual environment...")
        subprocess.check_call([python_executable, "-m", "pip", "install", "--upgrade", "pip"])
    
    return python_executable

def check_ollama_ready(url="http://localhost:11434"):
    """Poll Ollama until it's ready. Note: We use requests from the venv."""
    print("Waiting for Ollama to be ready...")
    
    # Simple retry logic using urllib to avoid venv dependency chicken-and-egg for this check
    # But since we install requests in step 0, we can use it if we run this script WITH the venv python.
    # However, this script is likely the ENTRY POINT. 
    # Simpler approach: Use urllib (std lib) for the health check.
    import urllib.request
    import urllib.error
    
    for _ in range(30):  # Wait up to 30 seconds
        try:
            with urllib.request.urlopen(url) as response:
                if response.status == 200:
                    print("Ollama is ready!")
                    return True
        except (urllib.error.URLError, ConnectionError):
            time.sleep(1)
    return False

def main():
    base_dir = os.getcwd()
    server_dir = os.path.join(base_dir, "server")
    docker_dir = os.path.join(base_dir, "docker")
    
    # 0. Setup Virtual Environment and Dependencies
    print("\n=== 0. Setting up Virtual Environment ===")
    venv_python = get_venv_python()
    
    print("Checking dependencies in virtual environment...")
    # Install requests (for script use) and model downloaders
    run_command(f"{venv_python} -m pip install requests sentence-transformers transformers torch", cwd=base_dir)

    # 1. Download Local Models
    print("\n=== 1. Checking/Downloading Local Models ===")
    
    # Check if models exist to avoid re-downloading if not needed
    emb_model_path = os.path.join(server_dir, "models", "embedding")
    ocr_model_path = os.path.join(server_dir, "models", "ocr")
    
    if not os.path.exists(emb_model_path):
        print("Downloading Embedding Model...")
        run_command(f"{venv_python} emb-download.py", cwd=server_dir)
    else:
        print(f"Embedding model found at {emb_model_path}")

    if not os.path.exists(ocr_model_path):
        print("Downloading OCR Model...")
        run_command(f"{venv_python} ocr-download.py", cwd=server_dir)
    else:
        print(f"OCR model found at {ocr_model_path}")

    # 2. Start Docker Containers
    print("\n=== 2. Starting Docker Containers ===")
    # Docker commands are system commands, so they don't use venv_python
    run_command("docker-compose up -d --build", cwd=docker_dir)
    
    # 3. Pull Ollama Model
    print("\n=== 3. Setting up Ollama Model ===")
    if check_ollama_ready():
        target_model = "ministral-3:8b" # Adjust this if needed
        
        print(f"Triggering pull for {target_model} inside Ollama container...")
        run_command(f"docker-compose exec ollama ollama pull {target_model}", cwd=docker_dir)
        print("Ollama model pulled successfully.")
    else:
        print("Warning: Ollama did not become ready in time. You may need to pull the model manually.")

    print("\n=== Setup Complete! ===")
    print("Services are running:")
    print("- OCR Service: http://localhost:8000")
    print("- Embedding Service: http://localhost:8001")
    print("- Ask Service: http://localhost:8002")

if __name__ == "__main__":
    main()
