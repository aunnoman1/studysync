# On-device MiniLM embedding (all-MiniLM-L6-v2)

## Contract (must match Python `SentenceTransformer.encode`)

1. **Tokenizer**: `bert-base-uncased` WordPiece (same as `AutoTokenizer.from_pretrained` for this model).
2. **ONNX inputs**: `input_ids`, `attention_mask` — int64, shape `[1, seq]` with `seq <= 128`, padding = 0.
3. **ONNX output**: `last_hidden_state` float32, shape `[1, seq, 384]`.
4. **Mean pooling** (sentence-transformers default): for each token position `t`, weight = `attention_mask[t]`.  
   `sum_embeddings = sum(hidden[t] * mask[t])`, `denom = sum(mask[t])`, `sentence_embedding = sum_embeddings / denom`.
5. **Normalize**: L2-normalize the 384-d vector (so cosine similarity = dot product).

Chunking for indexing uses the same character splitter as `server/embedding_service.py`
(RecursiveCharacterTextSplitter: chunk_size=700, chunk_overlap=120, same separators).

Re-export after changing transformers version if vectors drift.
