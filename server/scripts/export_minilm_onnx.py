#!/usr/bin/env python3
"""
Export sentence-transformers/all-MiniLM-L6-v2 to ONNX for on-device inference.

Outputs (default: ../../app/assets/onnx/minilm/):
  - model.onnx   — AutoModel forward (input_ids, attention_mask) -> last_hidden_state
  - vocab.txt    — WordPiece vocabulary (same as bert-base-uncased)
  - README.md    — tokenizer + pooling contract

Pooling is NOT in the graph: the app must apply mean pooling + L2 normalize
to match SentenceTransformer.encode (sentence-transformers).

Requires: torch, transformers, onnx (pip install torch transformers onnx).
Run from repo root or server/:  python scripts/export_minilm_onnx.py
"""
from __future__ import annotations

import argparse
import os
import sys

import onnx
import torch
import torch.nn as nn
from transformers import AutoModel, AutoTokenizer


MODEL_ID = "sentence-transformers/all-MiniLM-L6-v2"
# Max sequence length must match Dart tokenizer (sentence-transformers default 128 for MiniLM)
MAX_LENGTH = 128


class MiniLMOnnxWrapper(nn.Module):
    """Exports last_hidden_state only; pooling done in client."""

    def __init__(self, model: nn.Module):
        super().__init__()
        self.encoder = model

    def forward(self, input_ids: torch.Tensor, attention_mask: torch.Tensor):
        out = self.encoder(input_ids=input_ids, attention_mask=attention_mask)
        return out.last_hidden_state


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-o",
        "--out-dir",
        default=os.path.join(
            os.path.dirname(__file__), "..", "..", "app", "assets", "onnx", "minilm"
        ),
        help="Output directory for model.onnx and vocab.txt",
    )
    args = parser.parse_args()
    out_dir = os.path.abspath(args.out_dir)
    os.makedirs(out_dir, exist_ok=True)

    print(f"[export] Loading {MODEL_ID} ...")
    tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
    base = AutoModel.from_pretrained(MODEL_ID)
    base.eval()
    wrapped = MiniLMOnnxWrapper(base)
    wrapped.eval()

    # Dummy forward for ONNX trace
    dummy = tokenizer(
        "Hello world semantic search",
        return_tensors="pt",
        padding="max_length",
        truncation=True,
        max_length=MAX_LENGTH,
    )
    input_ids = dummy["input_ids"]
    attention_mask = dummy["attention_mask"]

    onnx_path = os.path.join(out_dir, "model.onnx")
    print(f"[export] Writing {onnx_path} ...")
    # Use legacy exporter for broader ONNX Runtime compatibility on mobile.
    torch.onnx.export(
        wrapped,
        (input_ids, attention_mask),
        onnx_path,
        input_names=["input_ids", "attention_mask"],
        output_names=["last_hidden_state"],
        dynamic_axes={
            "input_ids": {0: "batch", 1: "seq"},
            "attention_mask": {0: "batch", 1: "seq"},
            "last_hidden_state": {0: "batch", 1: "seq", 2: "hidden"},
        },
        opset_version=14,
        do_constant_folding=True,
        dynamo=False,
    )

    tokenizer.save_pretrained(out_dir)

    # Merge external weights into a single model.onnx for simpler mobile bundling.
    # Keep a conservative IR version for older on-device runtimes.
    merged = os.path.join(out_dir, "model_merged.onnx")
    proto = onnx.load(onnx_path, load_external_data=True)
    if proto.ir_version > 9:
        proto.ir_version = 9
    onnx.save(proto, merged)
    os.replace(merged, onnx_path)
    data_sidecar = onnx_path + ".data"
    if os.path.isfile(data_sidecar):
        os.remove(data_sidecar)
    # save_pretrained writes vocab.txt, tokenizer_config.json, etc.

    readme = os.path.join(out_dir, "README.md")
    with open(readme, "w", encoding="utf-8") as f:
        f.write(
            """# On-device MiniLM embedding (all-MiniLM-L6-v2)

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
"""
        )

    print(f"[export] Done. Files in: {out_dir}")
    print("  - model.onnx")
    print("  - vocab.txt (and tokenizer JSON from save_pretrained)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
