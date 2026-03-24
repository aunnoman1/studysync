import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:onnxruntime/onnxruntime.dart';

import 'bert_tokenizer.dart';
import 'recursive_character_text_splitter.dart';

const String _kModelAsset = 'assets/onnx/minilm/model.onnx';
const String _kVocabAsset = 'assets/onnx/minilm/vocab.txt';

const int kMiniLmHiddenSize = 384;
const int kMiniLmMaxSeqLen = 128;

/// On-device MiniLM embedding using ONNX (same vectors as server when tokenizer matches).
class LocalMinilmEmbedder {
  LocalMinilmEmbedder._(this._session, this._tokenizer);

  final OrtSession _session;
  final BertTokenizerForMiniLm _tokenizer;

  static LocalMinilmEmbedder? _instance;
  static String? _lastLoadError;
  static String? get lastLoadError => _lastLoadError;

  /// Returns null if assets are missing or ONNX init fails.
  static Future<LocalMinilmEmbedder?> tryLoad() async {
    if (_instance != null) return _instance;
    try {
      final modelBytes = await rootBundle.load(_kModelAsset);
      final vocabStr = await rootBundle.loadString(_kVocabAsset);
      final vocab = loadVocabFromLines(vocabStr.split('\n'));
      final tokenizer = BertTokenizerForMiniLm(
        vocab: vocab,
        unkToken: '[UNK]',
        clsToken: '[CLS]',
        sepToken: '[SEP]',
        padToken: '[PAD]',
      );
      final opts = OrtSessionOptions();
      opts.setIntraOpNumThreads(2);
      opts.setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);
      final session = OrtSession.fromBuffer(modelBytes.buffer.asUint8List(), opts);
      opts.release();
      _instance = LocalMinilmEmbedder._(session, tokenizer);
      _lastLoadError = null;
      return _instance;
    } catch (e) {
      _lastLoadError = e.toString();
      return null;
    }
  }

  static void dispose() {
    _instance?._session.release();
    _instance = null;
  }

  /// Mean-pooled + L2-normalized embedding (384-d).
  Float32List embed(String text) {
    final t = text.trim();
    if (t.isEmpty) {
      return Float32List(kMiniLmHiddenSize);
    }
    final enc = _tokenizer.encodePlus(text: t, maxLen: kMiniLmMaxSeqLen);
    final inputIds = enc.inputIds;
    final mask = enc.attentionMask;

    final inputIdsTensor = OrtValueTensor.createTensorWithDataList(
      [inputIds],
      [1, kMiniLmMaxSeqLen],
    );
    final maskTensor = OrtValueTensor.createTensorWithDataList(
      [mask],
      [1, kMiniLmMaxSeqLen],
    );
    final tokenTypeIdsTensor = OrtValueTensor.createTensorWithDataList(
      [List<int>.filled(kMiniLmMaxSeqLen, 0)],
      [1, kMiniLmMaxSeqLen],
    );
    final runOpts = OrtRunOptions();
    final outs = _session.run(
      runOpts,
      {
        'input_ids': inputIdsTensor,
        'attention_mask': maskTensor,
        'token_type_ids': tokenTypeIdsTensor,
      },
    );
    runOpts.release();
    inputIdsTensor.release();
    maskTensor.release();
    tokenTypeIdsTensor.release();

    final tensor = outs[0] as OrtValueTensor?;
    if (tensor == null) {
      throw StateError('ONNX returned no output');
    }
    final value = tensor.value;
    tensor.release();
    // ignore: avoid_dynamic_calls
    final batch = value as List<dynamic>;
    final seq0 = batch[0] as List<dynamic>;
    final seq = <List<double>>[];
    for (final row in seq0) {
      final r = row as List<dynamic>;
      seq.add(r.map((e) => (e as num).toDouble()).toList());
    }
    return meanNormalizeSentenceEmbedding(
      batch: [seq],
      attentionMask: mask,
      hiddenSize: kMiniLmHiddenSize,
    );
  }

  /// Chunk + embed each chunk (matches server chunk-and-embed).
  List<ChunkEmbeddingLocal> chunkAndEmbed(
    String text, {
    int chunkSize = 700,
    int chunkOverlap = 120,
  }) {
    final t = text.trim();
    if (t.isEmpty) return [];
    final splitter = RecursiveCharacterTextSplitter(
      chunkSize: chunkSize,
      chunkOverlap: chunkOverlap,
    );
    final chunks = splitter.splitText(t);
    return chunks
        .map((c) => ChunkEmbeddingLocal(chunkText: c, vector: embed(c)))
        .toList(growable: false);
  }
}

class ChunkEmbeddingLocal {
  ChunkEmbeddingLocal({required this.chunkText, required this.vector});
  final String chunkText;
  final Float32List vector;
}
