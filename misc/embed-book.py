import fitz  # PyMuPDF
import re
from typing import List, Dict, Any
from sentence_transformers import SentenceTransformer
from langchain_text_splitters import RecursiveCharacterTextSplitter
from supabase import create_client, Client

# ==========================================
# 1. CONFIGURATION
# ==========================================

# Supabase Credentials (Get these from your Project Settings -> API)
SUPABASE_URL = ""
SUPABASE_KEY = ""  # USE SERVICE_ROLE KEY to bypass RLS policies!

# Database Details
COURSE_ID = 1  # The ID of the course this book belongs to (e.g., CS101 = 1)
TABLE_NAME = "course_book_embedding"

# File Settings
PDF_PATH = "pf-book.pdf"
START_PDF_PAGE = 51    # Skip table of contents/preface (0-indexed)
END_PDF_PAGE = 1619    # None means process until the end
FIRST_BOOK_PAGE_NUM = 2

# Margins (Use the numbers you found with the visualization script)
MARGIN_TOP = 37
MARGIN_BOTTOM = 28
MARGIN_LEFT = 70
MARGIN_RIGHT = 35

# Embedding Model
MODEL_NAME = 'all-MiniLM-L6-v2'  # Produces 384-dimensional vectors
# ==========================================
# 2. HELPER CLASSES
# ==========================================

class ProcessedChunk:
    def __init__(self, text: str, page_num: int):
        self.text = text
        self.page_num = page_num
        self.vector = []

# ==========================================
# 3. FUNCTIONS
# ==========================================

def clean_text_artifacts(text: str) -> str:
    """Removes common PDF artifacts."""
    text = re.sub(r'\n+', '\n', text)
    text = re.sub(r'^\s*\d+\s*$', '', text, flags=re.MULTILINE)
    return text.strip()

def process_and_chunk_book() -> List[ProcessedChunk]:
    """
    Loops through the PDF page by page, cleans text, chunks it,
    and assigns the correct book page number.
    """
    print(f"📖 Opening PDF: {PDF_PATH}...")
    doc = fitz.open(PDF_PATH)

    end_index = END_PDF_PAGE if END_PDF_PAGE is not None else len(doc)

    # Initialize Splitter
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=600,
        chunk_overlap=100,
        separators=["\n\n", "\n", ". ", " ", ""]
    )

    all_processed_chunks = []

    print(f"⚙️ Processing pages {START_PDF_PAGE} to {end_index}...")

    # Loop through the selected PDF pages
    for i in range(START_PDF_PAGE, end_index):
        page = doc[i]

        # Calculate the "Human" page number (e.g., Page 1, Page 2...)
        # Logic: If we are on the 0th processed page, it is FIRST_BOOK_PAGE_NUM
        current_book_page = FIRST_BOOK_PAGE_NUM + (i - START_PDF_PAGE)

        # 1. Crop & Extract
        crop_box = fitz.Rect(
            MARGIN_LEFT,
            MARGIN_TOP,
            page.rect.width - MARGIN_RIGHT,
            page.rect.height - MARGIN_BOTTOM
        )
        raw_text = page.get_text(clip=crop_box)

        # 2. Clean
        cleaned_text = clean_text_artifacts(raw_text)

        if not cleaned_text:
            continue

        # 3. Chunk THIS page only
        # (This ensures the page metadata is accurate for these specific chunks)
        page_chunks = text_splitter.split_text(cleaned_text)

        # 4. Create objects
        for chunk_text in page_chunks:
            all_processed_chunks.append(
                ProcessedChunk(text=chunk_text, page_num=current_book_page)
            )

        if i % 20 == 0:
            print(f"   Processed PDF page {i} (Book Page {current_book_page})...")

    doc.close()
    print(f"✅ Extracted {len(all_processed_chunks)} total text chunks.")
    return all_processed_chunks

def generate_embeddings(chunks: List[ProcessedChunk]):
    """Generates vectors for the list of chunk objects."""
    print(f"🧠 Loading model '{MODEL_NAME}'...")
    model = SentenceTransformer(MODEL_NAME)

    # Extract just the text strings for the model
    text_list = [c.text for c in chunks]

    print(f"⚡ Generating embeddings...")
    vectors = model.encode(text_list, show_progress_bar=True).tolist()

    # Assign vectors back to the objects
    for chunk, vector in zip(chunks, vectors):
        chunk.vector = vector

def upload_to_supabase(chunks: List[ProcessedChunk]):
    """Uploads data including the new Page Number metadata."""
    print("🚀 Connecting to Supabase...")
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

    data_payload = []

    for chunk in chunks:
        data_payload.append({
            "course_id": COURSE_ID,
            "chunk_text": chunk.text,
            "vector_data": chunk.vector,
            "metadata": {
                "source": PDF_PATH,
                "page_number": chunk.page_num  # <--- HERE IS YOUR METADATA
            }
        })

    batch_size = 50
    total = len(data_payload)
    print(f"   Uploading {total} records...")

    for i in range(0, total, batch_size):
        batch = data_payload[i : i + batch_size]
        try:
            supabase.table(TABLE_NAME).insert(batch).execute()
            print(f"   Uploaded batch {i // batch_size + 1}")
        except Exception as e:
            print(f"❌ Error on batch {i}: {e}")

# ==========================================
# 4. MAIN EXECUTION
# ==========================================

if __name__ == "__main__":
    # 1. Process & Chunk (Page-by-Page)
    chunk_objects = process_and_chunk_book()

    if not chunk_objects:
        print("❌ No text found. Check your settings.")
        exit()

    # 2. Embed
    generate_embeddings(chunk_objects)

    # 3. Upload
    upload_to_supabase(chunk_objects)

    print("✅ Ingestion Complete!")
