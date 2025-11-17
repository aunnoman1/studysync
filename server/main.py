import io
import re  # <-- 1. ADDED IMPORT
from contextlib import asynccontextmanager
import torch
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import HTMLResponse, Response
from PIL import Image
from transformers import AutoProcessor, AutoModelForVision2Seq

# --- Global Variables for Model ---
processor = None
model = None
device = "cuda" if torch.cuda.is_available() else "cpu"
# Use bfloat16 for performance if available, otherwise float32
model_dtype = torch.bfloat16 if torch.cuda.is_available() else torch.float32
last_image_bytes = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Asynchronous context manager to load the model on startup
    and free it on shutdown.
    """
    global processor, model
    print(f"--- Loading model on device: {device} with dtype: {model_dtype} ---")

    local_model_path = "./models/ocr"
    processor = AutoProcessor.from_pretrained(local_model_path)
    # 2. UPDATED MODEL LOADING WITH DTYPE
    model = AutoModelForVision2Seq.from_pretrained(
        local_model_path,
        torch_dtype=model_dtype
    ).to(device)

    print("--- Model loading complete ---")
    yield
    print("--- Shutting down and cleaning up model ---")
    del model
    del processor
    if device == "cuda":
        torch.cuda.empty_cache()

# Create the FastAPI app with the lifespan event handler
app = FastAPI(lifespan=lifespan)

# 3. ADDED POST_PROCESS FUNCTION (MODIFIED FROM YOUR EXAMPLE)
def post_process_ocr(generated_text: str, prompt: str, scale_height: float, scale_width: float):
    """
    Parses the structured output from Kosmos 2.5 <ocr> prompt.
    Returns a list of blocks as dicts: { 'text': str, 'quad': [x1,y1,x2,y2,x3,y3,x4,y4] }
    Coords are scaled back to the original image pixel space using the provided scale factors.
    Falls back to parsing CSV-like lines if no <bbox> tags are found.
    """
    # Remove the prompt from the generated text
    text = generated_text.replace(prompt, "").strip()

    blocks = []

    # Pattern 1: Kosmos bbox tags with 4 coordinate pairs, followed by optional text
    # Example: <bbox><x_35><y_48><x_806><y_48><x_806><y_99><x_35><y_99></bbox>some text
    # Accept 2-pair (x1,y1,x2,y2) OR 4-pair (x1,y1,x2,y2,x3,y3,x4,y4)
    kosmos_pattern = re.compile(
        r"<bbox>"
        r"<x_(\d+)><y_(\d+)>"
        r"<x_(\d+)><y_(\d+)>"
        r"(?:<x_(\d+)><y_(\d+)><x_(\d+)><y_(\d+)>)?"
        r"</bbox>\s*([^\n<]*)",
        re.IGNORECASE,
    )
    for m in kosmos_pattern.finditer(text):
        g = m.groups()
        x1, y1, x2, y2 = map(int, g[:4])
        # Optional additional pairs (x3,y3,x4,y4)
        opt = g[4:8]
        raw_label = (g[8] or "").strip()

        if all(opt):
            x3, y3, x4, y4 = map(int, opt)
            quad = [x1, y1, x2, y2, x3, y3, x4, y4]
        else:
            # Build rectangle quad from two corners (x1,y1) top-left, (x2,y2) bottom-right
            quad = [x1, y1, x2, y1, x2, y2, x1, y2]

        # Scale back to original image size
        scaled = []
        for i, val in enumerate(quad):
            if i % 2 == 0:
                scaled.append(int(round(val * scale_width)))
            else:
                scaled.append(int(round(val * scale_height)))
        blocks.append({"text": raw_label, "quad": scaled})

    if blocks:
        return blocks

    # Pattern 2: Fallback for CSV-like lines (x1,y1,x2,y2,x3,y3,x4,y4[,text])
    # Example: 35,48,806,48,806,99,35,99,Some text here
    csv_lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    csv_pattern = re.compile(
        r"^\s*(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+),(\d+)(?:,(.*))?$"
    )
    for ln in csv_lines:
        m = csv_pattern.match(ln)
        if not m:
            continue
        nums = list(map(int, m.groups()[:8]))
        lbl = (m.group(9) or "").strip()
        scaled = []
        for i, val in enumerate(nums):
            if i % 2 == 0:
                scaled.append(int(round(val * scale_width)))
            else:
                scaled.append(int(round(val * scale_height)))
        blocks.append({"text": lbl, "quad": scaled})

    # If still nothing parsed, return empty list (caller can decide)
    return blocks


# 4. COMPLETELY REWRITTEN KOSMOS FUNCTION
def run_kosmos_ocr(image: Image.Image):
    """
    This is the "blocking" function that runs the AI model.
    We run this in a threadpool to avoid blocking the main server thread.
    Uses the correct <ocr> prompt and processing.
    """
    try:
        prompt = "<ocr>"
        raw_width, raw_height = image.size

        # Process the image and prompt
        inputs = processor(text=prompt, images=image, return_tensors="pt")

        # Get scaling factors
        # .item() converts the 0-dim tensor to a plain Python number
        height = inputs.pop("height").item()
        width = inputs.pop("width").item()

        scale_height = raw_height / height
        scale_width = raw_width / width

        # Move inputs to the correct device
        inputs = {k: v.to(device) if v is not None else None for k, v in inputs.items()}
        # Ensure flattened_patches has the correct dtype
        inputs["flattened_patches"] = inputs["flattened_patches"].to(model_dtype)

        # Generate the output
        generated_ids = model.generate(
            **inputs,
            max_new_tokens=1024,
            use_cache=True
        )

        # Decode the generated text
        generated_text = processor.batch_decode(
            generated_ids,
            skip_special_tokens=True
        )[0]

        print(f"--- RAW MODEL OUTPUT: '{generated_text}' ---")

        # Use the new post-processing function
        blocks = post_process_ocr(
            generated_text,
            prompt,
            scale_height,
            scale_width
        )
        return blocks

    except Exception as e:
        print(f"Error during model inference: {e}")
        raise e

@app.post("/ocr")
async def ocr_endpoint(file: UploadFile = File(...)):
    """
    The main API endpoint that your Flutter app will call.
    It accepts a multipart form upload with a key named 'file'.
    """
    print(f"--- RECEIVED FILE: {file.filename}, CONTENT_TYPE: {file.content_type} ---")
    if not file.content_type.startswith("image/"):
        print(f"--- REJECTED: Content type is not 'image/' ---")
        raise HTTPException(status_code=400, detail="Invalid file type. Please upload an image.")

    try:
        # Read the image file from the request
        image_bytes = await file.read()

        # --- 2. SAVE IMAGE TO GLOBAL VAR ---
        global last_image_bytes
        last_image_bytes = image_bytes
        # --- END OF DEBUG CODE ---

        # Open the image using PIL
        pil_image = Image.open(io.BytesIO(image_bytes)).convert("RGB")

    except Exception as e:
        print(f"Error reading image: {e}")
        raise HTTPException(status_code=400, detail=f"Could not read image file: {e}")

    try:
        # Run the blocking OCR function in a non-blocking way
        # 5. REMOVED THE "prompt" ARGUMENT AS IT'S NOW HARDCODED
        blocks = await run_in_threadpool(run_kosmos_ocr, pil_image)
        print(f"OCR BLOCKS: {len(blocks)}")
        return {"blocks": blocks}

    except Exception as e:
        # Handle errors that happened during the model inference
        print(f"Internal server error: {e}")
        raise HTTPException(status_code=500, detail=f"An error occurred during OCR processing: {e}")

# --- TEST ENDPOINT ---
@app.get("/test", response_class=HTMLResponse)
async def get_test_page():
    """
    Serves a simple HTML page to test the /ocr endpoint
    by uploading a file directly from the browser.
    """
    html_content = """
    <html>
        <head>
            <title>Test OCR Endpoint</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    margin: 40px;
                    background: #f0f2f5;
                    color: #333;
                    display: grid;
                    place-items: center;
                    min-height: 80vh;
                }
                h1 { color: #111; }
                div.container {
                    background: #ffffff;
                    padding: 30px;
                    border-radius: 12px;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.05);
                    width: 500px;
                }
                input[type="file"] {
                    margin-bottom: 20px;
                    padding: 10px;
                    border: 1px solid #ddd;
                    border-radius: 6px;
                    width: 95%;
                }
                input[type="submit"] {
                    background: #007aff;
                    color: white;
                    border: none;
                    padding: 12px 20px;
                    border-radius: 6px;
                    cursor: pointer;
                    font-size: 16px;
                    font-weight: 500;
                }
                input[type="submit"]:hover { background: #005ecb; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Test Kosmos 2.5 OCR</h1>
                <p>Select an image to upload and test the /ocr endpoint.</p>
                <!--
                This form POSTs to your /ocr endpoint,
                using multipart/form-data (required for files).
                The input name "file" matches your endpoint's parameter.
                -->
                <form action="/ocr" method="post" enctype="multipart/form-data">
                    <input type="file" name="file" id="file" accept="image/*">
                    <br>
                    <input type="submit" value="Upload and Test OCR">
                </form>
            </div>
        </body>
    </html>
    """
    return HTMLResponse(content=html_content)

# --- ENDPOINT TO VIEW LAST IMAGE ---
@app.get("/view-last-image")
async def get_last_image():
    """
    A debugging endpoint to view the last image that was POSTed to /ocr.
    This helps verify that the image was received correctly.
    """
    global last_image_bytes
    if last_image_bytes is None:
        raise HTTPException(status_code=404, detail="No image has been processed yet.")

    # We assume the Flutter app sent a JPEG, as per our previous fix.
    return Response(content=last_image_bytes, media_type="image/jpeg")

@app.get("/")
async def root():
    return {"message": "OCR server is running. POST images to /ocr or go to /test to upload. Go to /view-last-image to see the last uploaded image."}

# To run this app, save it as main.py and run:
# uvicorn main:app --reload --host 0.0.0.loc
