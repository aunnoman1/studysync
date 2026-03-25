import requests
import time

print("Creating dummy image...")
from PIL import Image
import io

img = Image.new('RGB', (100, 100), color='red')
buf = io.BytesIO()
img.save(buf, format='JPEG')
img_bytes = buf.getvalue()

print(f"Uploading {len(img_bytes)} bytes to http://localhost:8000/ocr...")
try:
    files = {'file': ('test.jpg', img_bytes, 'image/jpeg')}
    resp = requests.post("http://localhost:8000/ocr", files=files)
    print("Status:", resp.status_code)
    print("Response:", resp.text)
except Exception as e:
    print("FATAL ERROR:", e)
