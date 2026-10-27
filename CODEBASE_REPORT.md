# StudySync Codebase Report

## 1. Executive summary

StudySync is a cross-platform, AI-assisted study application built as a Flutter client with Python AI microservices and cloud integrations.

Its central workflow is:

1. A student captures or uploads handwritten or printed notes.
2. The app optionally lets the student mark diagrams and figures.
3. Images are sent to an OCR service powered by Microsoft Kosmos-2.5.
4. OCR returns text blocks with pixel coordinates.
5. The app stores the images, OCR blocks, diagrams, and metadata locally using ObjectBox.
6. OCR text is split into semantic chunks and converted into 384-dimensional MiniLM embeddings.
7. Embeddings are stored locally in an ObjectBox HNSW vector index.
8. Students can search their notes semantically.
9. Students can ask an AI tutor questions using local note content plus course-book content stored in Supabase/pgvector.
10. Notes can be exported/imported as `.studysync` archives and synchronized with Google Drive.
11. Students can participate in Supabase-powered course forums and attach their own notes.

The project is therefore a combination of:

- Digital handwritten-note scanner
- OCR and document reconstruction tool
- Offline semantic search engine
- Retrieval-Augmented Generation study tutor
- Diagram explanation assistant
- Community discussion platform
- Local note archive and Google Drive backup system

The Flutter application is the primary product. The backend is not one monolithic API; it is split into independent services for OCR, embeddings, and AI question answering.

---

## 2. Repository structure

```text
studysync/
├── app/                         Flutter application
│   ├── lib/
│   │   ├── app.dart             Main application shell and orchestration
│   │   ├── main.dart            Application startup
│   │   ├── env.dart             Environment configuration
│   │   ├── models/              ObjectBox and forum models
│   │   ├── pages/               Screens and feature workflows
│   │   ├── services/            API clients and business logic
│   │   └── widgets/             Reusable UI components
│   ├── assets/onnx/minilm/      On-device MiniLM model and tokenizer
│   ├── test/                    Flutter tests
│   ├── android/                 Android host project
│   ├── ios/                     iOS host project
│   ├── linux/                   Linux host project
│   ├── macos/                   macOS host project
│   ├── windows/                 Windows host project
│   └── web/                     Web host project
├── server/                      Python backend services
│   ├── main.py                  OCR service
│   ├── embedding_service.py     Embedding service
│   ├── ask_service.py           RAG and LLM service
│   ├── ocr-download.py          Downloads Kosmos OCR model
│   ├── emb-download.py          Downloads MiniLM embedding model
│   └── scripts/                 Model conversion utilities
├── docker/                      Dockerfiles and Compose configuration
├── misc/                        Book ingestion and OCR utilities
├── setup.sh                     Linux/macOS setup
├── setup.bat                    Windows setup
├── setup_and_run.py             Model download and Docker startup
├── CODEBASE_OVERVIEW.md         High-level project overview
├── report.md                    FYP/report documentation
├── swagger.json                 Intended API schema
└── test_ocr.py                  Simple OCR request test
```

The main business logic is concentrated in:

- `app/lib/app.dart`
- `app/lib/models/note_record.dart`
- `app/lib/pages/`
- `app/lib/services/`
- `server/main.py`
- `server/embedding_service.py`
- `server/ask_service.py`

---

## 3. Application architecture

### 3.1 High-level architecture

```text
                 ┌────────────────────────┐
                 │       Flutter App      │
                 │ Android/iOS/Desktop/Web│
                 └───────────┬────────────┘
                             │
       ┌─────────────────────┼──────────────────────┐
       │                     │                      │
       ▼                     ▼                      ▼
 ObjectBox local DB     Python AI services       Supabase
 notes/images/OCR       OCR, embeddings, LLM     auth/forum/vector books
 vectors/diagrams
       │
       ▼
 Google Drive appDataFolder
 note backup and synchronization
```

### 3.2 Local-first design

User-created notes are primarily stored locally using ObjectBox.

The local database contains:

- Original note images
- OCR-ready images
- OCR text blocks
- Diagram crops
- Diagram explanations
- Text chunks
- Embedding vectors
- Note metadata

The cloud services are mainly processing and collaboration services. Local search can continue to work if the remote embedding server is unavailable because the app contains an ONNX MiniLM model.

This is consistent with the newer implementation direction described in `app/currentplan.txt`, although that document is partially outdated. The current source code also includes Google Drive synchronization and Supabase community features that the plan describes as future or manual functionality.

---

## 4. Flutter application startup

### `app/lib/main.dart`

Startup performs these actions:

1. Initializes Flutter bindings.
2. Loads `.env`.
3. Initializes Supabase.
4. Opens the ObjectBox database.
5. Starts `StudySyncApp`.

```dart
await dotenv.load(fileName: ".env");
await Supabase.initialize(
  url: Env.supabaseUrl,
  anonKey: Env.supabaseAnonKey,
);
final db = await ObjectBox.create();
runApp(StudySyncApp(db: db));
```

### `app/lib/env.dart`

Configuration is read from environment variables:

| Variable | Purpose | Default |
|---|---|---|
| `SERVER_URL` | OCR server | `http://localhost:8000` |
| `EMBED_URL` | Embedding server | `http://localhost:8001` |
| `ASK_URL` | Ask/LLM server | `http://localhost:8002` |
| `SUPABASE_URL` | Supabase project URL | Placeholder URL |
| `SUPABASE_ANON_KEY` | Supabase public key | Empty |
| `GOOGLE_DESKTOP_CLIENT_ID` | Desktop Drive OAuth | None |
| `GOOGLE_DESKTOP_CLIENT_SECRET` | Desktop Drive OAuth | None |
| `GOOGLE_WEB_CLIENT_ID` | Web Google client | None |
| `GOOGLE_SERVER_CLIENT_ID` | Google server client ID | None |

The application therefore requires a correctly configured `.env` file for a functional deployment.

---

## 5. Main application shell and navigation

### `app/lib/app.dart`

`StudySyncApp` is the root Material application. It configures:

- Light theme
- Dark theme
- Global theme switching
- Application title
- `_AppShell` as the home widget

`_AppShellState` acts as the main application coordinator. It owns:

- Authentication state
- Guest mode state
- Current tab
- Loaded local notes
- Currently opened note
- OCR progress and error state
- Embedding progress and error state
- Drive synchronization state
- Service instances
- Navigation transitions

The main navigation tabs are defined in `app/lib/widgets/sidebar.dart`.

Expected tabs include:

- Dashboard
- My Notes
- Search
- AI Tutor
- Community
- Profile
- Cloud Sync

On narrow screens, the sidebar becomes a drawer. On wider screens, it is displayed persistently.

---

## 6. Authentication

### `app/lib/pages/auth_page.dart`

Authentication is handled through Supabase Auth.

Supported flows:

- Login with email/password
- Registration with email/password
- Username metadata during registration
- Guest mode

During registration, username metadata is passed to Supabase:

```dart
data: {'username': _usernameController.text.trim()}
```

The app also attempts to create or update a row in the `profiles` table.

The authentication page listens to Supabase auth state changes and automatically closes itself after a session is established.

### Guest mode

Guest mode only changes local Flutter state:

```dart
isAuthenticated = true;
useGuestMode = true;
```

It does not create a Supabase session.

Consequences:

- Guest users can access local note features.
- Guest users can use local storage and local search.
- Guest users cannot create community threads.
- Guest users cannot reply to forum discussions.
- The profile screen may still display them as not logged in because it checks the actual Supabase user.

This is an intentional distinction between application access and cloud authentication.

---

## 7. Local data model

### `app/lib/models/note_record.dart`

The local ObjectBox model contains five entities.

### 7.1 `NoteRecord`

Represents a complete note.

Important fields:

- `id`
- `title`
- `course`
- `textContent`
- `createdAt`
- `updatedAt`
- `ocrProcessed`
- `embeddingProcessed`

Relations:

```text
NoteRecord
├── images       → NoteImage
└── textChunks   → TextChunk
```

`textContent` is optional and is used for manually written text notes.

### 7.2 `NoteImage`

Represents one page or image inside a note.

Fields:

- Display image bytes
- Optional OCR-masked image bytes
- Creation date
- OCR completion flag

Relations:

```text
NoteImage
├── note       → NoteRecord
├── ocrBlocks  → OcrBlock
└── diagrams   → NoteDiagram
```

The display image can contain cyan outlines around selected diagrams. The OCR image has the diagrams blacked out so OCR focuses on surrounding text.

### 7.3 `OcrBlock`

Represents a detected text region.

Fields:

- Text
- Page number
- Reading order
- Quadrilateral coordinates

Coordinates are stored as eight packed integers:

```text
[x1, y1, x2, y2, x3, y3, x4, y4]
```

They are stored inside a byte vector.

### 7.4 `TextChunk`

Represents a semantically meaningful chunk of OCR text.

Fields:

- `chunkText`
- 384-dimensional embedding
- `orderIndex`
- Parent note

The embedding field is indexed using ObjectBox HNSW:

```dart
@HnswIndex(dimensions: 384)
```

This is the foundation of local semantic search.

### 7.5 `NoteDiagram`

Represents a manually selected diagram or figure.

Fields:

- Cropped image bytes
- Coordinates
- Optional AI explanation
- Optional 384-dimensional embedding

The diagram vector is stored but is not currently included in the normal `SearchService` search over `TextChunk` records.

---

## 8. Note capture and ingestion workflow

### `app/lib/pages/note_capture_page.dart`

The note creation screen supports:

- Camera capture on mobile
- Gallery image selection
- Multi-image upload
- Desktop filesystem selection
- Image reordering
- Image deletion
- Note title
- Course selection
- Optional manually written text
- Diagram selection

Supported course labels are currently hard-coded:

```text
PF
OOP
DSA
DB
```

If the user does not provide a title:

- Image-based note → `Photo Note`
- Text-only note → `Text Note`

### Image processing

Images are processed in an isolate so that image manipulation does not freeze the UI.

The processing pipeline:

1. Decode image.
2. Apply EXIF orientation.
3. Crop selected diagrams.
4. Create a display image with cyan diagram outlines.
5. Create an OCR image with diagrams blacked out.
6. Store diagram crops and coordinates.
7. Re-encode images as JPEG.

Each selected rectangle becomes a `DiagramExtraction`.

The app stores:

- Display image
- OCR image
- Diagram crop
- Diagram quadrilateral

After the note is saved, the note is inserted into ObjectBox immediately. OCR then runs asynchronously.

---

## 9. OCR pipeline

### Client: `app/lib/services/ocr_service.dart`

The Flutter client sends a multipart request:

```text
POST /ocr
file = image/jpeg
```

The service expects:

```json
{
  "blocks": [
    {
      "text": "detected text",
      "quad": [x1, y1, x2, y2, x3, y3, x4, y4]
    }
  ]
}
```

The client validates that each quadrilateral contains exactly eight integers.

### Server: `server/main.py`

The OCR service uses:

- FastAPI
- Pillow
- PyTorch
- Hugging Face Transformers
- Microsoft Kosmos-2.5

The model is loaded during FastAPI startup from:

```text
./models/ocr
```

The service automatically selects:

- CUDA when available
- CPU otherwise

It uses:

- `bfloat16` on CUDA
- `float32` on CPU

### OCR processing

The image is passed to Kosmos with:

```text
<ocr>
```

The model output is parsed in `post_process_ocr()`.

The parser supports:

1. Kosmos bounding-box markup:

```text
<bbox><x_35><y_48>...</bbox>Some text
```

2. CSV-style fallback lines:

```text
x1,y1,x2,y2,x3,y3,x4,y4,text
```

Coordinates are scaled from the model's internal image dimensions back to the original image's pixel dimensions.

### OCR endpoint

```text
POST /ocr
```

Behavior:

1. Validates the MIME type starts with `image/`.
2. Reads the uploaded bytes.
3. Converts the image to RGB using Pillow.
4. Runs OCR in a thread pool.
5. Returns OCR blocks.

Additional debugging endpoints:

```text
GET /
GET /test
GET /view-last-image
```

`/test` serves a basic browser upload page.

`/view-last-image` returns the most recently uploaded image.

---

## 10. Digital note reconstruction

### `app/lib/widgets/note_digital_view.dart`

The application can reconstruct a digital representation of the original page.

Instead of displaying only the raw photograph, it:

1. Loads OCR blocks.
2. Converts stored coordinates into rectangles.
3. Scales coordinates into the available UI size.
4. Renders text near its original position.
5. Renders selected diagrams in their original location.
6. Allows diagrams to be tapped for detail.

The user can switch between:

- Digital view
- Original image view

The diagram detail modal displays:

- Cropped diagram
- AI explanation, if available

This is one of the more distinctive features of the project: it does not merely extract plain text; it attempts to preserve the visual structure of the original page.

---

## 11. Diagram explanation pipeline

After OCR completes for an image, the app checks whether the image contains selected diagrams.

For every diagram without an explanation:

1. The cropped diagram image is sent to the Ask service.
2. OCR text from the same page is passed as optional context.
3. The LLM explains the diagram.
4. The explanation is embedded.
5. The explanation and vector are saved to ObjectBox.

Client endpoint:

```text
POST /explain-diagram
```

The request contains:

```json
{
  "image_base64": "...",
  "context": "OCR text from the page"
}
```

The backend supports:

- Ollama vision models
- Google Generative AI models

The prompt asks the model to explain:

- What the diagram represents
- Relationships between components
- Key concepts illustrated

---

## 12. Embedding pipeline

### Client: `app/lib/services/embedding_service.dart`

The Flutter embedding service supports two paths.

#### Remote path

The app calls:

```text
POST /embedding/embed
POST /embedding/chunk-and-embed
```

Remote calls have a two-second timeout.

#### Local fallback path

If the remote request fails, the app attempts to load the ONNX MiniLM model bundled in:

```text
app/assets/onnx/minilm/model.onnx
```

The fallback uses:

- BERT WordPiece tokenization
- Maximum sequence length of 128
- Mean pooling
- L2 normalization
- 384-dimensional vectors

The intended model is:

```text
sentence-transformers/all-MiniLM-L6-v2
```

### Server: `server/embedding_service.py`

The server uses:

- Sentence Transformers
- `all-MiniLM-L6-v2`
- LangChain `RecursiveCharacterTextSplitter`

Supported endpoints:

```text
GET  /embedding/health
POST /embedding/embed
POST /embedding/embed-batch
POST /embedding/chunk-and-embed
```

The server loads the model from:

```text
models/embedding
```

It supports CUDA and CPU execution.

### Chunking

Default chunk parameters:

```text
chunk_size = 700 characters
chunk_overlap = 120 characters
```

Separators are attempted in this order:

```text
double newline
newline
sentence ending
semicolon
colon
comma
space
individual characters
```

The same splitter logic is implemented in Dart in:

```text
app/lib/services/local_embedding/recursive_character_text_splitter.dart
```

This allows local fallback embeddings to use the same chunking strategy as the server.

---

## 13. When embeddings are generated

In the current implementation, embeddings are triggered after all images belonging to a note have completed OCR.

The app:

1. Loads all images for the note.
2. Loads OCR blocks for every image.
3. Sorts blocks approximately by vertical position, then horizontal position.
4. Joins the OCR text.
5. Sends the combined text to `chunk-and-embed`.
6. Deletes any previous chunks.
7. Stores the new chunks and vectors.
8. Marks the note as embedding-processed.

Important detail: the current embedding text is built from OCR blocks only.

The following are not included in the regular note embedding text:

- `NoteRecord.textContent`
- Diagram explanations
- Raw image contents without OCR

Consequently, a purely text-based note may not become searchable through the current embedding path, because embeddings are only started from the OCR image workflow.

---

## 14. Semantic search

### `app/lib/services/search_service.dart`

Search flow:

1. Ignore empty queries.
2. Check whether any `TextChunk` records exist.
3. Generate an embedding for the query.
4. Use ObjectBox HNSW nearest-neighbor search.
5. Retrieve up to `limit * 5` chunks.
6. Filter results by distance.
7. Keep the best chunk per note.
8. Sort notes by vector distance.
9. Return the best notes.

Default values:

```text
limit = 10
maxDistance = 1.4
```

The returned result contains:

- Note
- Similarity/distance score
- Matching text chunk

The search UI is implemented in:

```text
app/lib/pages/search_page.dart
```

Search works offline when the ONNX embedding fallback can load successfully.

---

## 15. AI tutor and RAG

### Client: `app/lib/pages/ai_tutor_page.dart`

The AI Tutor UI contains:

- Chat history
- User message bubbles
- AI response bubbles
- Markdown rendering
- Streaming response updates
- Automatic scrolling
- Loading state
- Error display

The UI uses:

```text
POST /ask/stream
```

The client collects up to eight local chunks from ObjectBox.

Notably, it currently selects recent chunks by ObjectBox ID rather than performing local nearest-neighbor retrieval first:

```dart
query(TextChunk_.id, flags: Order.descending)
```

The Ask backend then re-embeds those local chunks and scores them against the question.

### Backend: `server/ask_service.py`

The Ask service performs:

1. Question embedding.
2. Supabase course-book retrieval.
3. Local chunk embedding and scoring.
4. Context combination.
5. Top-five selection.
6. Prompt generation.
7. LLM invocation.
8. Streaming or non-streaming response.

### Supabase retrieval

The service calls a Supabase RPC function:

```text
match_course_book_chunks
```

The default RPC name can be changed through:

```text
SUPABASE_MATCH_FN
```

The default match count is five.

The request can optionally include a course filter.

Expected course-book records contain concepts such as:

- `chunk_text`
- `similarity`
- `course_id`
- `metadata`

The book ingestion utility `misc/embed-book.py` inserts course-book chunks into Supabase with:

- Course ID
- Chunk text
- 384-dimensional embedding
- PDF source
- Page number metadata

### Local context scoring

For each supplied local chunk:

1. The Ask service embeds the chunk.
2. It computes cosine similarity against the question embedding.
3. It attaches note title and note ID metadata.
4. It sorts local chunks by similarity.

The service combines:

```text
Supabase hits + local note hits
```

Then it keeps the top five contexts overall.

### LLM prompt

The prompt defines the LLM as a Computer Science professor.

It instructs the model to:

- Answer directly
- Avoid referring to “the context”
- Avoid saying “according to the notes”
- Present examples naturally
- Use a conversational and confident tone
- Avoid introductory filler

### Supported LLM providers

#### Ollama

Default provider:

```text
LLM_PROVIDER=ollama
```

Default model:

```text
phi
```

Default URL:

```text
http://localhost:11434
```

#### Google Generative AI

Alternative provider:

```text
LLM_PROVIDER=google
```

Configuration includes:

- `GOOGLE_API_KEY`
- `GOOGLE_MODEL`

The service supports both standard and streaming Google responses.

### Streaming

The endpoint returns Server-Sent Events:

```text
data: generated text

data: [DONE]
```

Errors are sent as:

```text
data: [ERROR] ...
```

This allows the Flutter UI to display the answer as it is generated rather than waiting for the entire response.

---

## 16. Community forum

### Client files

- `app/lib/pages/community_page.dart`
- `app/lib/pages/thread_detail_page.dart`
- `app/lib/services/forum_supabase_service.dart`
- `app/lib/models/forum_models.dart`

### Expected Supabase tables

The client expects tables named:

- `course`
- `thread`
- `comment`
- `profiles`
- `thread_attachment`

It also expects a storage bucket:

```text
forum_file
```

### Community features

Users can:

- Browse courses
- Filter threads by course
- Search threads by title
- Create threads
- Reply to threads
- Reply to individual comments
- View nested comment trees
- Attach exported StudySync notes
- Download and preview attached notes
- Delete threads

### Thread creation

Creating a thread requires a real Supabase user.

The user supplies:

- Course
- Title
- Question
- Optional local note attachment

If a note is attached:

1. The note is exported as a StudySync archive.
2. The archive is uploaded to Supabase Storage.
3. A `thread_attachment` record is inserted.

### Comment trees

Comments are fetched flat from Supabase and converted into nested trees using:

```text
buildCommentTree()
```

The tree is ordered chronologically.

---

## 17. Google Drive synchronization

### Client files

- `drive_auth_service.dart`
- `google_drive_api_client.dart`
- `drive_sync_service.dart`
- `drive_sync_state_store.dart`
- `drive_sync_settings_page.dart`

### Authentication

The app requests the Drive application-data scope:

```text
https://www.googleapis.com/auth/drive.appdata
```

Supported platforms include:

- Web
- Android
- iOS
- Linux
- Windows
- macOS

Desktop Linux and Windows use a separate OAuth flow with locally stored serialized credentials.

### Storage location

Files are stored in Google Drive's private:

```text
appDataFolder
```

The files are not ordinary user-visible Drive files.

### File format

Remote files use:

```text
application/x-studysync-note
```

Filenames look like:

```text
note-42-data-structures.studysync
```

The content is a JSON archive containing base64-encoded image and OCR data.

### Synchronization states

The app represents notes as:

- `synced`
- `localOnly`
- `driveOnly`

The sync screen displays these states and provides operations to:

- Upload local-only notes
- Download Drive-only notes
- Refresh synchronization state
- Delete local copy
- Delete Drive copy
- Delete both copies

### Conflict resolution

When both local and remote versions exist:

- Newer local note → upload local version
- Newer Drive file → replace local note from Drive
- Equal timestamps → treat as synchronized

The comparison uses:

- Local `updatedAt`
- Drive `modifiedTime`

### Important implementation detail

Matching is primarily based on a sanitized note title, not a stable cross-device note UUID.

This means notes with identical or similar titles may collide or be interpreted as the same logical note.

---

## 18. Import/export archives

### `app/lib/services/note_transfer_service.dart`

The application can export selected notes to `.studysync` files.

The archive contains:

- Note metadata
- Original image bytes
- OCR blocks
- Diagram crops
- Diagram explanations
- Diagram embeddings
- Text chunks
- Text embeddings
- Processing flags
- Timestamps

The archive format is JSON encoded as UTF-8 bytes.

### Archive versions

`NoteArchiveCodec` supports:

- Version 1
- Version 2

Version 2 added diagram data.

Imports handle duplicate note titles by renaming them:

```text
Original
Original2
Original3
```

Deletion is implemented manually by removing:

1. OCR blocks
2. Diagrams
3. Images
4. Text chunks
5. The root note

---

## 19. Note viewing and editing

### `app/lib/pages/note_photo_view_page.dart`

The note viewer supports:

- Original image view
- Digital OCR reconstruction
- Multiple-page navigation
- Rename
- Course update
- Manual text update
- Add more images
- Delete current image
- Delete entire note
- OCR retry
- Embedding retry
- OCR block count
- Embedding chunk count

When a page is deleted, the note's embeddings are invalidated and recomputed if remaining pages have OCR data.

### `app/lib/pages/note_debug_page.dart`

The debug screen exposes:

- OCR blocks
- OCR coordinates
- Text chunks
- Embedding-related information

It is opened through a debug floating action button while viewing a note.

---

## 20. Dashboard

### `app/lib/pages/dashboard_page.dart`

The dashboard contains:

- Recent notes
- AI Tutor quick access
- Community activity card

It uses responsive grid layouts:

- One column on small screens
- Two columns on medium screens
- Three columns on large screens

It includes animated entrance effects and hover card behavior.

The AI Tutor quick-access card can send an initial question directly to the Tutor screen.

---

## 21. Profile and theme management

### `app/lib/pages/profile_page.dart`

The profile screen displays:

- Username
- Email
- Avatar-style UI
- Login/register controls when unauthenticated
- Logout
- Theme selection

The application has a global `themeModeNotifier` allowing light/dark theme switching.

### `app/lib/theme.dart`

The theme defines:

- Colors
- Surface styles
- Borders
- Typography
- Card decoration
- Light and dark themes
- Button styles
- Input field styles

---

## 22. Backend services

### 22.1 OCR service

File:

```text
server/main.py
```

Port:

```text
8000
```

Main endpoint:

```text
POST /ocr
```

Technology:

- FastAPI
- Kosmos-2.5
- Transformers
- PyTorch
- Pillow

GPU support is available through CUDA.

### 22.2 Embedding service

File:

```text
server/embedding_service.py
```

Port:

```text
8001
```

Endpoints:

```text
GET  /embedding/health
POST /embedding/embed
POST /embedding/embed-batch
POST /embedding/chunk-and-embed
```

Technology:

- FastAPI
- Sentence Transformers
- MiniLM
- LangChain text splitting
- PyTorch

### 22.3 Ask service

File:

```text
server/ask_service.py
```

Port:

```text
8002
```

Endpoints:

```text
POST /ask
POST /ask/stream
POST /explain-diagram
```

Technology:

- FastAPI
- HTTPX
- Supabase REST RPC
- Ollama
- Google GenAI
- Pydantic

The Ask service depends on the embedding service for question and local-chunk embeddings.

---

## 23. Docker deployment

### `docker/docker-compose.yml`

The Compose configuration defines:

- `ocr-service`
- `embedding-service`
- `ollama`
- `ask-service`

Ports:

```text
8000 → OCR
8001 → embeddings
8002 → Ask service
11434 → Ollama
```

The OCR and embedding services request NVIDIA GPU resources.

The Ollama service stores model data in a named volume:

```text
ollama_data
```

Models are mounted from:

```text
server/models/ocr
server/models/embedding
```

### Dockerfiles

#### `Dockerfile.ocr`

Uses:

```text
pytorch/pytorch:2.3.0-cuda12.1-cudnn8-runtime
```

Installs OCR dependencies and starts `main.py`.

#### `Dockerfile.embedding`

Uses the same PyTorch CUDA image and installs Sentence Transformers and LangChain dependencies.

#### `Dockerfile.ask`

Uses Python 3.11 slim because the Ask service is primarily I/O and orchestration.

---

## 24. Setup process

### `setup.sh` and `setup.bat`

The setup scripts:

1. Create a Python virtual environment.
2. Install model-download dependencies.
3. Run `setup_and_run.py`.

### `setup_and_run.py`

The setup process:

1. Checks whether local embedding and OCR models exist.
2. Downloads them if missing.
3. Runs:

```text
docker-compose up -d --build
```

4. Waits for Ollama.
5. Pulls an Ollama model.

The script currently pulls:

```text
qwen2.5vl:7b-q4_K_M
```

However, `ask_service.py` defaults to:

```text
phi
```

Unless `OLLAMA_MODEL` is configured, the setup script and runtime default are inconsistent.

---

## 25. Utility scripts

### `server/ocr-download.py`

Downloads and saves:

```text
microsoft/kosmos-2.5
```

to:

```text
server/models/ocr
```

### `server/emb-download.py`

Downloads:

```text
sentence-transformers/all-MiniLM-L6-v2
```

to:

```text
server/models/embedding
```

### `server/scripts/export_minilm_onnx.py`

Exports MiniLM to ONNX for local Flutter inference.

It produces:

- `model.onnx`
- `vocab.txt`
- Tokenizer files
- README describing the pooling contract

### `misc/embed-book.py`

This is a course-book ingestion pipeline.

It:

1. Opens a PDF using PyMuPDF.
2. Crops page margins.
3. Extracts text.
4. Removes page-number artifacts.
5. Splits pages into chunks.
6. Embeds chunks with MiniLM.
7. Uploads them to Supabase.
8. Stores page-number metadata.

### `misc/coords-check.py`

A visual debugging tool for checking PDF crop margins.

### `test_ocr.py`

Creates a red 100×100 JPEG and sends it to the OCR endpoint.

---

## 26. Tests

The repository has very limited automated testing.

Current Flutter tests are in:

```text
app/test/recursive_splitter_test.dart
```

They test:

- Newline splitting behavior
- Basic recursive chunk splitting

`test_ocr.py` is an integration-style manual script, not a formal test suite.

There are no apparent comprehensive tests for:

- Authentication
- OCR parsing
- ObjectBox persistence
- Drive sync
- Conflict resolution
- Forum operations
- RAG retrieval
- LLM streaming
- Diagram extraction
- Import/export compatibility

The generated Android, iOS, macOS, and runner test files are standard Flutter scaffolding.

---

## 27. Important implementation observations

### 27.1 Manual text notes are not fully indexed

A note can be created with only manually typed text and no images.

However, embedding generation is currently triggered from the OCR/image path. Therefore, a text-only note may not receive `TextChunk` records and may not appear in semantic search or local AI context.

### 27.2 Manual note text is excluded from normal embeddings

`_runEmbeddingsForNote()` builds its text from OCR blocks. It does not append `NoteRecord.textContent`.

This means manually entered text is stored and displayed but may not be searchable by the vector index.

### 27.3 Diagram explanations are not part of normal note search

Diagram explanations receive their own vector, but `SearchService` searches only `TextChunk` vectors.

Diagram explanations are viewable but are not currently integrated into ordinary semantic note retrieval.

### 27.4 AI Tutor retrieval is not the same as Search retrieval

The Search page performs ObjectBox nearest-neighbor retrieval.

The AI Tutor currently gathers up to eight recent chunks and sends them to the Ask service, which re-embeds and scores them. It does not directly reuse `SearchService` to retrieve the most relevant chunks locally.

### 27.5 Supabase authorization should be verified

In `server/ask_service.py`, the Supabase request currently constructs:

```python
"Authorization": f"******"
```

This appears to be a literal redacted value rather than a real bearer token. The RPC call may fail unless this is corrected or intentionally handled elsewhere.

### 27.6 OCR debugging state is global

The OCR service stores the latest uploaded image in a process-global variable for `/view-last-image`.

This is useful for debugging but is not suitable for multi-user production behavior.

Also, if `/view-last-image` is called before any OCR request has initialized the variable, the endpoint may not behave as intended.

### 27.7 Drive matching relies on titles

Drive synchronization uses sanitized titles as logical keys.

Potential consequences:

- Two notes with the same title can collide.
- Renaming a note may create a new logical identity.
- Note IDs are included in filenames but are not the primary reconciliation key.

### 27.8 Remote and local embeddings need model compatibility

The local ONNX model and server MiniLM model are designed to produce compatible 384-dimensional vectors, but tokenizer/model version drift could affect search quality.

The ONNX export README explicitly states that re-exporting may be needed if Transformers versions change.

### 27.9 Docker and Ollama configuration are slightly inconsistent

The setup script pulls `qwen2.5vl:7b-q4_K_M`, while the Ask service defaults to `phi`.

The desired model should be explicitly configured through:

```text
OLLAMA_MODEL
```

### 27.10 Ask service deployment dependency is implicit

The Ask container depends on the embedding service but not explicitly on Ollama in Compose. It may start before Ollama is ready, although requests may succeed later once Ollama becomes available.

### 27.11 `swagger.json` is not currently usable as an API contract

The checked-in Swagger file appears incomplete or inaccessible through the current Supabase-related tooling. The actual API behavior is defined more reliably by the FastAPI source and Dart clients.

---

## 28. Typical end-to-end user journey

### Creating a note

1. User opens My Notes.
2. User selects camera or image upload.
3. User adds one or more pages.
4. User reorders pages.
5. User optionally marks diagrams.
6. User enters title, course, and manual text.
7. App processes images in an isolate.
8. App stores the note locally.
9. OCR runs asynchronously.
10. OCR blocks are saved.
11. Selected diagrams are explained by the AI service.
12. OCR text is chunked and embedded.
13. Text chunks are stored in ObjectBox.
14. The note becomes available for search and AI context.

### Searching notes

1. User enters a natural-language query.
2. Query is embedded remotely or locally.
3. ObjectBox HNSW searches local vectors.
4. Results are grouped by note.
5. Matching notes and chunks are displayed.

### Asking the tutor

1. User enters a question.
2. The app collects local chunks.
3. The Ask service embeds the question and local chunks.
4. Supabase course-book chunks are retrieved.
5. Local and remote contexts are combined.
6. Top five contexts are passed to the LLM.
7. The answer streams back to Flutter.
8. Markdown is rendered in the chat.

### Syncing with Google Drive

1. User connects Google Drive.
2. App lists `.studysync` files from `appDataFolder`.
3. Local notes and remote files are matched by sanitized title.
4. Newer versions overwrite older versions.
5. Local-only or remote-only items can be uploaded/downloaded manually.

---

## 29. Overall assessment

StudySync is a substantial final-year-project codebase with a strong feature set and a clear product concept. Its most important architectural decision is the local-first storage and vector-search model:

- User notes remain in ObjectBox.
- Search can work offline.
- The backend is used for expensive AI tasks.
- Google Drive provides optional backup.
- Supabase provides authentication, community, and course knowledge.

The most complete areas are:

- Flutter application shell
- Local ObjectBox note model
- OCR-to-digital reconstruction
- Remote/local embedding fallback
- Google Drive archive synchronization
- Forum data model and UI
- Streaming AI tutor interface

The areas that appear less mature are:

- Automated testing
- Production error handling
- Stable synchronization identity
- Text-only note indexing
- Integration of diagram explanations into retrieval
- Supabase authorization configuration
- Deployment consistency between setup scripts and runtime defaults

In short, the project is an AI-powered, cross-platform study workspace that transforms photographed notes into structured, searchable, locally stored learning material and then combines those notes with external course knowledge to provide tutoring, diagram explanations, community discussion, and cloud backup.
