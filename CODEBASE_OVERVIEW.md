# StudySync – Codebase Overview

## What is StudySync?

StudySync is an **AI-powered study assistant** application (final year project / FYP). It lets students capture handwritten or printed notes via photos, run OCR on them, store them locally, sync to Google Drive, search semantically, and ask an AI tutor questions answered via RAG (Retrieval-Augmented Generation) from their own notes.

---

## Repository Structure

```
studysync/
├── app/          # Flutter frontend (cross-platform mobile/desktop/web)
├── server/       # Python AI backend (FastAPI microservices)
├── docker/       # Docker configuration for the backend services
├── misc/         # Utility/scripts for pre-processing books/embeddings
├── setup.sh/.bat # Setup scripts
└── setup_and_run.py
```

---

## Key Technologies

### Frontend – Flutter (`app/`)
- **Flutter (Dart)** – cross-platform UI (Android, iOS, Linux, macOS, Windows, Web)
- **ObjectBox** – on-device NoSQL database with vector search (HNSW index) for note storage and local semantic search
- **Supabase** – cloud backend for authentication and server-side vector search via pgvector
- **Google Sign-In + Drive API** – authentication and cloud note backup/sync
- **flutter_markdown** – renders AI responses with full Markdown formatting
- **shared_preferences** – persists lightweight settings

### Backend – Python (`server/`)
Three independent **FastAPI** microservices:

| Service | Port | Purpose |
|---|---|---|
| `main.py` (OCR) | 8000 | Image → structured text blocks with bounding boxes |
| `embedding_service.py` | 8001 | Text → vector embeddings + chunk-splitting |
| `ask_service.py` | 8002 | RAG orchestrator: embedding + Supabase retrieval + LLM |

Plus an **Ollama** container (port 11434) serving the LLM locally (configurable, default `phi`).

**Key Python libs:** `transformers`, `torch`, `sentence-transformers`, `langchain-text-splitters`, `langchain-ollama`, `FastAPI`, `Pillow`, `httpx`

---

## How the Code is Organized

### Flutter App (`app/lib/`)

```
lib/
├── main.dart              # Entry point, initializes ObjectBox + Supabase
├── app.dart               # Root widget, navigation shell, all state management
├── env.dart               # Environment config (API URLs)
├── theme.dart             # App-wide design system
├── objectbox.dart         # ObjectBox store wrapper
├── models/
│   └── note_record.dart   # 4 entities: NoteRecord, NoteImage, OcrBlock, TextChunk
├── pages/
│   ├── dashboard_page.dart           # Home: recent notes, quick AI access
│   ├── auth_page.dart                # Login/guest mode
│   ├── note_capture_page.dart        # Photo capture → OCR pipeline
│   ├── note_photo_view_page.dart     # View OCR overlays on images
│   ├── my_notes_page.dart            # Notes list/management
│   ├── ai_tutor_page.dart            # Chat interface with AI tutor
│   ├── search_page.dart              # Semantic search over notes
│   ├── community_page.dart           # Community study features
│   ├── profile_page.dart             # User profile
│   ├── drive_sync_settings_page.dart # Google Drive sync management
│   └── note_debug_page.dart          # Debug view for OCR/embedding data
└── services/
    ├── ocr_service.dart              # HTTP client → OCR microservice
    ├── embedding_service.dart        # HTTP client → embedding microservice
    ├── ask_service.dart              # HTTP client → ask/RAG microservice
    ├── search_service.dart           # Local semantic search using ObjectBox HNSW
    ├── drive_auth_service.dart       # Google Drive OAuth
    ├── drive_sync_service.dart       # Bidirectional Drive sync logic + conflict resolution
    ├── drive_sync_state_store.dart   # Persists sync mapping state
    ├── google_drive_api_client.dart  # Drive REST API wrapper
    ├── note_transfer_service.dart    # Note import/export serialization
    └── note_archive_codec.dart       # Binary codec for note archives
```

### Python Backend (`server/`)

- **`main.py`** – OCR service using **Microsoft Kosmos-2.5** vision model; accepts image uploads, returns text blocks with quadrilateral pixel coordinates.
- **`embedding_service.py`** – Sentence-Transformers based; exposes `/embed`, `/embed-batch`, `/chunk-and-embed` endpoints; uses LangChain's `RecursiveCharacterTextSplitter`.
- **`ask_service.py`** – RAG pipeline: embeds the question → queries Supabase for course-book chunks (via `match_course_book_chunks` RPC) + scores local note chunks by cosine similarity → top-5 contexts fed to Ollama LLM with a "CS Professor" persona prompt.

### Docker (`docker/`)

`docker-compose.yml` orchestrates all 4 services (OCR, embedding, ask, ollama), all GPU-accelerated via NVIDIA runtime with model directories mounted as volumes.

---

## Core Data Flow

1. **Capture**: User photographs notes → `NoteCapturePage` → image sent to OCR service → `OcrBlock` records (text + bounding boxes) saved to ObjectBox.
2. **Embed**: OCR text assembled → sent to embedding service → `TextChunk` records with 384-dim float vectors saved to ObjectBox (HNSW-indexed).
3. **Ask**: User types question → local chunks sent alongside query to ask service → RAG retrieval from Supabase + local scoring → Ollama LLM generates response → rendered as Markdown in chat UI.
4. **Sync**: Notes serialized to binary archive → uploaded/downloaded from Google Drive `appDataFolder`; conflict resolution based on `updatedAt` timestamps.
