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
    
    model_id = "microsoft/kosmos-2.5"
    processor = AutoProcessor.from_pretrained(model_id)
    # 2. UPDATED MODEL LOADING WITH DTYPE
    model = AutoModelForVision2Seq.from_pretrained(
        model_id, 
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
def post_process_ocr(generated_text: str, prompt: str, scale_height: float, scale_width: float) -> str:
    """
    Parses the structured output from Kosmos 2.5 <ocr> prompt.
    Returns only the detected text, joined by newlines.
    """
    # Remove the prompt from the generated text
    text = generated_text.replace(prompt, "").strip()
    
    # Define the regex pattern for bounding boxes
    pattern = r"<bbox><x_\d+><y_\d+><x_\d+><y_\d+></bbox>"
    
    # Split the text by the bounding box pattern.
    # The first element is usually empty, so we take [1:]
    lines = re.split(pattern, text)[1:]
    
    if not lines:
        # If no bounding boxes were found, the model might have returned
        # plain text. Let's try to clean it.
        if "the text is:" in text.lower():
            text = text.split(":", 1)[-1].strip()
        return text

    # We just want the text, not the coordinates.
    # Join all detected text lines with a newline.
    return "\n".join(line.strip() for line in lines)


# 4. COMPLETELY REWRITTEN KOSMOS FUNCTION
def run_kosmos_ocr(image: Image.Image) -> str:
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
        output_text = post_process_ocr(
            generated_text, 
            prompt, 
            scale_height, 
            scale_width
        )
            
        return output_text

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
        ocr_result = await run_in_threadpool(run_kosmos_ocr, pil_image)
        
        # Return the successful result
        print(f"OCR RESULT: {ocr_result}")
        return {"text": ocr_result}

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