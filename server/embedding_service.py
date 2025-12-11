import os
from contextlib import asynccontextmanager
from typing import List, Dict, Any

import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from fastapi.responses import JSONResponse

try:
    from dotenv import load_dotenv  # type: ignore
    load_dotenv()
except Exception:
    pass

from sentence_transformers import SentenceTransformer
from langchain_text_splitters import RecursiveCharacterTextSplitter


# ----------------------------
# Config / Globals
# ----------------------------
device = "cuda" if torch.cuda.is_available() else "cpu"
MODEL_PATH = os.getenv(
    "EMB_MODEL_PATH",
    os.path.join("models", "embedding"),
)
MODEL_NAME = os.path.basename(MODEL_PATH)

_model: SentenceTransformer | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global _model
    try:
        print(f"[embedding] Loading model from: {MODEL_PATH} on device: {device}")
        _model = SentenceTransformer(MODEL_PATH, device=device)
        print("[embedding] Model ready.")
        yield
    finally:
        _model = None
        if device == "cuda":
            torch.cuda.empty_cache()
        print("[embedding] Shutdown complete.")


app = FastAPI(title="Embedding Service", lifespan=lifespan)


# ----------------------------
# Models
# ----------------------------
class EmbedRequest(BaseModel):
    text: str = Field(..., description="Text to embed")


class EmbedBatchRequest(BaseModel):
    texts: List[str] = Field(..., description="List of texts to embed")


class ChunkAndEmbedRequest(BaseModel):
    text: str = Field(..., description="Source text to split and embed")
    chunk_size: int = Field(700, description="Target chunk size (characters)")
    chunk_overlap: int = Field(120, description="Overlap size between chunks (characters)")


# ----------------------------
# Helpers
# ----------------------------
def _require_model() -> SentenceTransformer:
    if _model is None:
        raise HTTPException(status_code=503, detail="Model not loaded yet.")
    return _model


def _chunk_text(text: str, chunk_size: int, chunk_overlap: int) -> List[str]:
    """
    Split text using LangChain's RecursiveCharacterTextSplitter which favors
    semantic boundaries when possible, with graceful fallback to character splits.
    """
    chunk_size = max(1, int(chunk_size))
    chunk_overlap = max(0, int(chunk_overlap))
    if chunk_overlap >= chunk_size:
        chunk_overlap = max(0, chunk_size - 1)
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        separators=[
            "\n\n", "\n", ". ", "! ", "? ", "; ", ": ",
            ", ", " ", ""  # increasingly finer splits
        ],
    )
    docs = splitter.create_documents([text])
    return [d.page_content for d in docs]


def _to_float_list(vec) -> List[float]:
    # vec can be numpy.ndarray or torch.Tensor
    if hasattr(vec, "tolist"):
        return [float(x) for x in vec.tolist()]
    return [float(x) for x in vec]


# ----------------------------
# Routes
# ----------------------------
@app.get("/embedding/health")
async def health() -> Dict[str, Any]:
    return {"status": "ok", "device": device, "model": MODEL_NAME}


@app.post("/embedding/embed")
async def embed(req: EmbedRequest) -> JSONResponse:
    model = _require_model()
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="text must be non-empty")
    try:
        emb = model.encode(req.text, convert_to_tensor=False, device=device, show_progress_bar=False)
        vec = _to_float_list(emb)
        return JSONResponse({"vector": vec, "dim": len(vec), "model": MODEL_NAME})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Embedding failed: {e}") from e


@app.post("/embedding/embed-batch")
async def embed_batch(req: EmbedBatchRequest) -> JSONResponse:
    model = _require_model()
    texts = [t for t in req.texts if isinstance(t, str) and t.strip()]
    if not texts:
        raise HTTPException(status_code=400, detail="texts must contain at least one non-empty string")
    try:
        embs = model.encode(texts, convert_to_tensor=False, device=device, show_progress_bar=False)
        out = [_to_float_list(e) for e in embs]
        dim = len(out[0]) if out else 0
        return JSONResponse({"vectors": out, "dim": dim, "count": len(out), "model": MODEL_NAME})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Batch embedding failed: {e}") from e


@app.post("/embedding/chunk-and-embed")
async def chunk_and_embed(req: ChunkAndEmbedRequest) -> JSONResponse:
    model = _require_model()
    text = req.text or ""
    if not text.strip():
        raise HTTPException(status_code=400, detail="text must be non-empty")
    chunks = _chunk_text(text, req.chunk_size, req.chunk_overlap)
    try:
        embs = model.encode(chunks, convert_to_tensor=False, device=device, show_progress_bar=False)
        out = [{"chunk_text": c, "vector": _to_float_list(e)} for c, e in zip(chunks, embs)]
        dim = len(out[0]["vector"]) if out else 0
        return JSONResponse({"embeddings": out, "dim": dim, "count": len(out), "model": MODEL_NAME})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Chunk+embed failed: {e}") from e


# Register /ask routes
def _embed_text(text: str) -> List[float]:
    """Helper function to embed text using the loaded model."""
    model = _require_model()
    emb = model.encode(text, convert_to_tensor=False, device=device, show_progress_bar=False)
    return _to_float_list(emb)




if __name__ == "__main__":
    import uvicorn

    host = os.getenv("HOST", "0.0.0.0")
    port = int(os.getenv("EMB_PORT", "8001"))
    uvicorn.run("embedding_service:app", host=host, port=port, reload=True)


