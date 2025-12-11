import os
import math
import inspect
from typing import Any, Dict, List, Optional, Callable, Union, Awaitable

import httpx
from fastapi import HTTPException, FastAPI
from pydantic import BaseModel, Field
from langchain_ollama import OllamaLLM

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


# Initialize Ollama LLM (lazy loading)
_llm: Optional[OllamaLLM] = None

def _get_llm() -> OllamaLLM:
    """Get or create the Ollama LLM instance."""
    global _llm
    if _llm is None:
        model_name = os.getenv("OLLAMA_MODEL", "phi")
        base_url = os.getenv("OLLAMA_BASE_URL", "http://localhost:11434")
        _llm = OllamaLLM(model=model_name, base_url=base_url)
    return _llm


async def _call_llm(prompt: str, question: str) -> str:
    """
    Call Ollama LLM with the given prompt.
    Uses the model specified in OLLAMA_MODEL env var (default: phi).
    """
    try:
        llm = _get_llm()
        # Run LLM in thread pool since it's synchronous
        import asyncio
        from concurrent.futures import ThreadPoolExecutor
        
        loop = asyncio.get_event_loop()
        with ThreadPoolExecutor() as executor:
            response = await loop.run_in_executor(
                executor,
                lambda: llm.invoke(prompt)
            )
        return str(response.content if hasattr(response, 'content') else response)
    except Exception as e:
        print(f"[ERROR] LLM call failed: {e}")
        raise HTTPException(status_code=500, detail=f"LLM call failed: {e}") from e


def _cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """Compute cosine similarity between two vectors."""
    if len(vec1) != len(vec2) or len(vec1) == 0:
        return 0.0
    dot = sum(a * b for a, b in zip(vec1, vec2))
    mag1 = math.sqrt(sum(a * a for a in vec1))
    mag2 = math.sqrt(sum(b * b for b in vec2))
    if mag1 == 0 or mag2 == 0:
        return 0.0
    return dot / (mag1 * mag2)


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


async def _call_embed(fn: Callable[[str], Union[List[float], Awaitable[List[float]]]], text: str) -> List[float]:
    res = fn(text)
    if inspect.isawaitable(res):
        return await res
    return res


def register_ask_routes(app: FastAPI, embed_text_fn: Callable[[str], Union[List[float], Awaitable[List[float]]]]):
    @app.post("/ask", response_model=AskResponse)
    async def ask(req: AskRequest) -> AskResponse:
        question = (req.question or "").strip()
        if not question:
            raise HTTPException(status_code=400, detail="question must be non-empty")

        try:
            q_vec = await _call_embed(embed_text_fn, question)
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

        # Local chunks from client - score them using embeddings
        local_hits: List[AskContext] = []
        for lc in req.local_chunks:
            txt = (lc.text or "").strip()
            if not txt:
                continue
            # Embed the local chunk text and compute similarity with query
            try:
                chunk_vec = await _call_embed(embed_text_fn, txt)
                similarity = _cosine_similarity(q_vec, chunk_vec)
            except Exception as e:
                print(f"[WARNING] Failed to score local chunk: {e}")
                similarity = 0.0  # Fallback to 0 if embedding fails
            
            local_hits.append(
                AskContext(
                    source="local",
                    text=txt,
                    score=similarity,  # Now properly scored
                    note_title=lc.note_title,
                    note_id=lc.note_id,
                )
            )
        
        # Sort local hits by score (descending)
        local_hits.sort(key=lambda h: h.score, reverse=True)

        # Combine and sort all contexts by score (descending)
        contexts = supa_hits + local_hits
        contexts.sort(key=lambda h: h.score, reverse=True)
        
        # Keep only top 5 highest scoring contexts
        contexts = contexts[:5]

        # 1. Format the context chunks first
        # We separate metadata (Source/Title) from content so the LLM knows what is what.
        context_text = ""
        for ctx in contexts:
            context_text += f"{ctx.text}\n\n"
        
        # 2. Construct the V3 "Teacher Persona" Prompt
        prompt = f"""
### ROLE
You are a passionate Computer Science Professor. You are explaining a concept to a student during office hours. 

### CONTEXT (INTERNAL MEMORY)
The following text is your internal knowledge. You must teach these concepts as if you have known them for years. 
**DO NOT** refer to this text as "the context," "the book," or "the notes."

<internal_memory>
{context_text}
</internal_memory>

### STUDENT QUESTION
{question}

### STRICT STYLE RULES
1. **Absolute Prohibition on Meta-Talk:**
   - NEVER use phrases like: "Based on the provided knowledge", "According to the text", "In the examples provided", "As seen in Example 10-6".
   - If the text says "In Example 10-6 we see...", you must rewrite it to: "For instance, consider a case where..."

2. **Claim the Examples:**
   - If the context contains a code example, present it as *your* example. 
   - BAD: "The text shows an inventory class."
   - GOOD: "Let's look at an inventory class to understand this."

3. **Tone:** Conversational, confident, and direct.

### OUTPUT FORMAT
(Start directly with the answer. Do not use introductory filler.)

### EXAMPLES OF BEHAVIOR
**Input Context:** "Figure 4.2 in the textbook shows that recursion uses the stack."
**Bad Response:** "According to Figure 4.2 in the provided text, recursion uses the stack."
**Good Response:** "Recursion relies heavily on the call stack to manage function states."

**Input Context:** "User notes: frequent crashes on Pixel 9."
**Bad Response:** "Your notes mention the Pixel 9 crashes."
**Good Response:** "The Pixel 9 has known stability issues regarding frequent crashes."
"""
        # Send prompt to LLM
        llm_response = await _call_llm(prompt, question)
        print(f"[DEBUG] LLM response length: {len(llm_response)}")
        print(f"[DEBUG] LLM response preview: {llm_response[:100]}...")
        
        # Dump prompt and response to temp.txt for debugging/integration
        try:
            from datetime import datetime
            with open("temp.txt", "w", encoding="utf-8") as f:
                f.write("=" * 80 + "\n")
                f.write("AI Tutor Response\n")
                f.write("=" * 80 + "\n")
                f.write(f"Question: {question}\n")
                f.write(f"Timestamp: {datetime.now().isoformat()}\n")
                f.write(f"Number of contexts used: {len(contexts)}\n\n")
                f.write("=" * 80 + "\n")
                f.write("PROMPT SENT TO LLM:\n")
                f.write("=" * 80 + "\n")
                f.write(prompt)
                f.write("\n\n")
                f.write("=" * 80 + "\n")
                f.write("LLM RESPONSE:\n")
                f.write("=" * 80 + "\n")
                f.write(llm_response)
                f.write("\n")
                f.write("=" * 80 + "\n")
            print(f"[DEBUG] Saved prompt and response to temp.txt")
        except Exception as e:
            print(f"[WARNING] Failed to write to temp.txt: {e}")
        
        response = AskResponse(message=llm_response)
        print(f"[DEBUG] Returning response with message length: {len(response.message)}")
        return response


if __name__ == "__main__":
    import uvicorn

    async def remote_embed_text(text: str) -> List[float]:
        # Connect to embedding service
        # Default to localhost:8001 if not specified
        emb_url = os.getenv("EMBEDDING_SERVER_URL", "http://localhost:8001")
        # Remove trailing slash if present
        if emb_url.endswith("/"):
            emb_url = emb_url[:-1]
            
        async with httpx.AsyncClient() as client:
            # We assume embedding service endpoint is /embedding/embed
            # server/embedding_service.py has: @app.post("/embedding/embed")
            resp = await client.post(
                f"{emb_url}/embedding/embed",
                json={"text": text},
                timeout=30.0
            )
            resp.raise_for_status()
            data = resp.json()
            return data["vector"]

    app = FastAPI(title="Ask Service Standalone")
    
    register_ask_routes(app, remote_embed_text)
    
    host = os.getenv("HOST", "0.0.0.0")
    # Default to 8002 to avoid conflict with embedding service (8001) and main (8000)
    port = int(os.getenv("ASK_PORT", "8002"))
    
    print(f"Starting Ask Service on {host}:{port}")
    print(f"Using Embedding Service at: {os.getenv('EMBEDDING_SERVER_URL', 'http://localhost:8001')}")
    
    uvicorn.run(app, host=host, port=port)
