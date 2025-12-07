import fitz  # PyMuPDF
from PIL import Image, ImageDraw

def visualize_crop(pdf_path, page_num=10, top=50, bottom=50, left=50, right=50):
    """
    Saves an image of a PDF page with the proposed crop box drawn in red.
    Adjust margins until the red box excludes headers, footers, and side numbers.
    """
    try:
        doc = fitz.open(pdf_path)
        if page_num >= len(doc):
            print(f"Error: PDF only has {len(doc)} pages.")
            return

        page = doc[page_num]
        rect = page.rect

        # 1. Render the page to an image
        pix = page.get_pixmap()
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

        # 2. Calculate the crop box coordinates
        # Format: [x0, y0, x1, y1]
        # x0 = Left margin
        # y0 = Top margin
        # x1 = Width minus Right margin
        # y1 = Height minus Bottom margin
        crop_box = [
            left,
            top,
            rect.width - right,
            rect.height - bottom
        ]

        # 3. Draw the red box to show what will be KEPT
        draw = ImageDraw.Draw(img)
        draw.rectangle(crop_box, outline="red", width=5)

        # 4. Save and notify
        output_filename = f"crop_preview_page_{page_num}.png"
        img.save(output_filename)
        print(f"Saved preview to {output_filename}")
        print(f"Red Box Dimensions: {crop_box}")
        print(f"Anything OUTSIDE the red line will be DELETED.")

        doc.close()

    except Exception as e:
        print(f"An error occurred: {e}")

# --- CONFIGURATION ---
PDF_PATH = "pf-book.pdf"
TEST_PAGE = 1349

# Vertical Margins (Headers/Footers)
TOP_MARGIN = 37
BOTTOM_MARGIN = 28

# Horizontal Margins (Side Page Numbers)
LEFT_MARGIN = 70   # Increase to cut from the left edge
RIGHT_MARGIN = 35  # Increase to cut from the right edge

# Run the function
visualize_crop(PDF_PATH, TEST_PAGE, TOP_MARGIN, BOTTOM_MARGIN, LEFT_MARGIN, RIGHT_MARGIN)
