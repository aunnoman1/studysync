# fyp

A new Flutter project.

## Offline smart search (ONNX MiniLM)

Smart search can run **without** the embedding server if `assets/onnx/minilm/model.onnx` is present. Generate it once:

```bash
cd ../server && source env/bin/activate && pip install onnx onnxscript torch transformers
python scripts/export_minilm_onnx.py
```

See `assets/onnx/README.md`. The file is large (~90MB) and is gitignored by default.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
