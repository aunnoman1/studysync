# On-device MiniLM embeddings

This folder holds assets for **offline** semantic search (same model family as the Python embedding service: `sentence-transformers/all-MiniLM-L6-v2`).

## Files

| File | Description |
|------|-------------|
| `minilm/model.onnx` | ONNX export of the transformer (~90MB). Not committed by default if listed in `.gitignore`; generate locally. |
| `minilm/vocab.txt` | WordPiece vocabulary (from `tokenizer.save_pretrained`). |
| `minilm/tokenizer.json` | Optional; Dart tokenizer uses `vocab.txt` only. |

## Generating `model.onnx`

From the repo root (with Python deps including `torch`, `transformers`, `onnx`):

```bash
cd server
source env/bin/activate   # or your venv
pip install onnx onnxscript
python scripts/export_minilm_onnx.py
```

Outputs go to `app/assets/onnx/minilm/` and merge weights into a **single** `model.onnx` for Flutter assets.

## App size / CI

Bundling `model.onnx` adds on the order of **~90MB** to the app binary. For store limits, consider:

- Download-on-first-launch (host the file on your CDN and cache under `getApplicationSupportDirectory`), or
- Per-ABI split builds if you move to platform-specific ONNX builds later.

## Vector contract

See `minilm/README.md` (generated next to the model) for mean pooling + L2 normalization details. Vectors must match the server’s `SentenceTransformer.encode` for search against existing `TextChunk` rows.
