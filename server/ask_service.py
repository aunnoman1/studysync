import os
from typing import Any, Dict, List, Optional, Callable

import httpx
from fastapi import HTTPException, FastAPI
from pydantic import BaseModel, Field

try:
    from dotenv import load_dotenv  # type: ignore
    load_dotenv()
except Exception:
    pass

# Env config
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_MATCH_FN = os.getenv("SUPABASE_MATCH_FN", "match_course_book_chunks")
SUPABASE_MATCH_COUNT = int(os.getenv("SUPABASE_MATCH_COUNT", "5"))


class LocalChunk(BaseModel):
    text: str
    note_title: Optional[str] = None
    note_id: Optional[int] = None


class AskRequest(BaseModel):
    question: str = Field(..., description="User question")
    local_chunks: List[LocalChunk] = Field(default_factory=list, description="Local note chunks text")
    match_count: int = Field(SUPABASE_MATCH_COUNT, description="Top matches to fetch from Supabase")
    course_id: Optional[int] = Field(None, description="Optional course filter for Supabase")


class AskContext(BaseModel):
    source: str
    text: str
    score: float
    note_title: Optional[str] = None
    note_id: Optional[int] = None
    course_id: Optional[int] = None
    metadata: Optional[Dict[str, Any]] = None


class AskResponse(BaseModel):
    message: str  # LLM-generated response to the question


async def _call_llm_dummy(prompt: str, question: str) -> str:
    """
    Dummy LLM function for development.
    In production, this will call your actual LLM API (OpenAI, Anthropic, etc.)
    """
    # Simulate LLM processing delay
    import asyncio
    await asyncio.sleep(0.5)
    
    # Return a simple dummy message
    return "to be integrated"


async def _supabase_match(
    query_vec: List[float],
    match_count: int,
    course_id: Optional[int],
) -> List[AskContext]:
    if not SUPABASE_URL or not SUPABASE_ANON_KEY:
        return []
    url = f"{SUPABASE_URL}/rest/v1/rpc/{SUPABASE_MATCH_FN}"
    headers = {
        "apikey": SUPABASE_ANON_KEY,
        "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
    }
    payload: Dict[str, Any] = {
        "query_embedding": query_vec,
        "match_count": match_count,
    }
    if course_id is not None:
        payload["filter_course_id"] = course_id

    async with httpx.AsyncClient(timeout=30.0) as client:
        resp = await client.post(url, headers=headers, json=payload)
    if resp.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"Supabase match failed: {resp.status_code} {resp.text}",
        )
    data = resp.json()
    if not isinstance(data, list):
        return []
    hits: List[AskContext] = []
    for row in data:
        if not isinstance(row, dict):
            continue
        text = str(row.get("chunk_text") or row.get("content") or "")
        similarity = float(row.get("similarity") or row.get("score") or 0.0)
        hits.append(
            AskContext(
                source="supabase",
                text=text,
                score=similarity,
                course_id=row.get("course_id"),
                metadata=row.get("metadata") if isinstance(row.get("metadata"), dict) else None,
            )
        )
    hits.sort(key=lambda h: h.score, reverse=True)
    return hits


def register_ask_routes(app: FastAPI, embed_text_fn: Callable[[str], List[float]]):
    @app.post("/ask", response_model=AskResponse)
    async def ask(req: AskRequest) -> AskResponse:
        question = (req.question or "").strip()
        if not question:
            raise HTTPException(status_code=400, detail="question must be non-empty")

        try:
            q_vec = embed_text_fn(question)
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Question embedding failed: {e}") from e

        # Supabase matches
        supa_hits: List[AskContext] = []
        try:
            supa_hits = await _supabase_match(q_vec, req.match_count, req.course_id)
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Supabase call failed: {e}") from e

        # Local chunks from client (no server-side scoring)
        local_hits: List[AskContext] = []
        for lc in req.local_chunks:
            txt = (lc.text or "").strip()
            if not txt:
                continue
            local_hits.append(
                AskContext(
                    source="local",
                    text=txt,
                    score=1.0,  # client-provided; not re-scored here
                    note_title=lc.note_title,
                    note_id=lc.note_id,
                )
            )

        contexts = supa_hits + local_hits

        prompt_lines = [
            "You are an assistant answering questions using the provided context.",
            f"Question: {question}",
            "Context:",
        ]
        for i, ctx in enumerate(contexts, start=1):
            prefix = "Supabase" if ctx.source == "supabase" else "Local"
            title = f" | title: {ctx.note_title}" if ctx.note_title else ""
            prompt_lines.append(f"[{i}] ({prefix}{title}) {ctx.text}")
        prompt_lines.append("Answer concisely based only on the context above.")
        prompt = "\n".join(prompt_lines)

        # Send prompt to LLM (dummy function for now)
        llm_response = await _call_llm_dummy(prompt, question)
        print(f"[DEBUG] LLM response length: {len(llm_response)}")
        print(f"[DEBUG] LLM response preview: {llm_response[:100]}...")
        
        # Dump response to temp.txt for debugging/integration
        try:
            with open("temp.txt", "w", encoding="utf-8") as f:
                f.write("=" * 80 + "\n")
                f.write("AI Tutor Response\n")
                f.write("=" * 80 + "\n")
                f.write(f"Question: {question}\n")
                f.write(f"Timestamp: {__import__('datetime').datetime.now()}\n\n")
                f.write("-" * 80 + "\n")
                f.write("PROMPT SENT TO LLM:\n")
                f.write("-" * 80 + "\n")
                f.write(prompt + "\n\n")
                f.write("-" * 80 + "\n")
                f.write("LLM RESPONSE:\n")
                f.write("-" * 80 + "\n")
                f.write(llm_response + "\n")
                f.write("=" * 80 + "\n")
        except Exception as e:
            print(f"Warning: Failed to write to temp.txt: {e}")
        
        response = AskResponse(message=llm_response)
        print(f"[DEBUG] Returning response with message length: {len(response.message)}")
        return response

