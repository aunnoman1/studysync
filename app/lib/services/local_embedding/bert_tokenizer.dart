// Port of HuggingFace transformers BertTokenizer / BasicTokenizer / WordpieceTokenizer
// for sentence-transformers/all-MiniLM-L6-v2 (bert-base-uncased vocab).

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:unicode/unicode.dart' as u;

/// Loads vocab.txt (one token per line, index = id).
Map<String, int> loadVocabFromLines(List<String> lines) {
  final m = <String, int>{};
  for (var i = 0; i < lines.length; i++) {
    final t = lines[i].trimRight();
    m[t] = i;
  }
  return m;
}

List<String> whitespaceTokenize(String text) {
  final t = text.trim();
  if (t.isEmpty) return [];
  return t.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
}

bool _isWhitespaceRune(int cp) {
  final s = String.fromCharCode(cp);
  if (s == ' ' || s == '\t' || s == '\n' || s == '\r') return true;
  return u.isSpaceSeparator(cp);
}

bool _isControlRune(int cp) {
  final s = String.fromCharCode(cp);
  if (s == '\t' || s == '\n' || s == '\r') return false;
  return u.isControl(cp);
}

bool _isPunctuationRune(int cp) {
  if ((cp >= 33 && cp <= 47) ||
      (cp >= 58 && cp <= 64) ||
      (cp >= 91 && cp <= 96) ||
      (cp >= 123 && cp <= 126)) {
    return true;
  }
  return u.isConnectorPunctuation(cp) ||
      u.isDashPunctuation(cp) ||
      u.isClosePunctuation(cp) ||
      u.isFinalPunctuation(cp) ||
      u.isInitialPunctuation(cp) ||
      u.isOtherPunctuation(cp) ||
      u.isOpenPunctuation(cp);
}

String _cleanText(String text) {
  final out = StringBuffer();
  for (final ch in text.runes) {
    if (ch == 0 || ch == 0xFFFD || _isControlRune(ch)) continue;
    if (_isWhitespaceRune(ch)) {
      out.write(' ');
    } else {
      out.write(String.fromCharCode(ch));
    }
  }
  return out.toString();
}

String _runStripAccents(String text) {
  final out = StringBuffer();
  for (final ch in text.runes) {
    if (u.isNonspacingMark(ch)) continue;
    out.write(String.fromCharCode(ch));
  }
  return out.toString();
}

bool _isChineseChar(int cp) {
  return (cp >= 0x4E00 && cp <= 0x9FFF) ||
      (cp >= 0x3400 && cp <= 0x4DBF) ||
      (cp >= 0x20000 && cp <= 0x2A6DF) ||
      (cp >= 0x2A700 && cp <= 0x2B73F) ||
      (cp >= 0x2B740 && cp <= 0x2B81F) ||
      (cp >= 0x2B820 && cp <= 0x2CEAF) ||
      (cp >= 0xF900 && cp <= 0xFAFF) ||
      (cp >= 0x2F800 && cp <= 0x2FA1F);
}

String _tokenizeChineseChars(String text) {
  final out = StringBuffer();
  for (final ch in text.runes) {
    if (_isChineseChar(ch)) {
      out.write(' ${String.fromCharCode(ch)} ');
    } else {
      out.write(String.fromCharCode(ch));
    }
  }
  return out.toString();
}

/// BasicTokenizer (do_lower_case=true, strip_accents follows lowercase default).
class BertBasicTokenizer {
  BertBasicTokenizer({
    this.doLowerCase = true,
    this.tokenizeChineseChars = true,
    bool? stripAccents,
  }) : stripAccents = stripAccents ?? true;

  final bool doLowerCase;
  final bool tokenizeChineseChars;
  final bool stripAccents;

  List<String> tokenize(String text) {
    var t = _cleanText(text);
    if (tokenizeChineseChars) {
      t = _tokenizeChineseChars(t);
    }
    var origTokens = whitespaceTokenize(t);
    final splitTokens = <String>[];
    for (var token in origTokens) {
      if (doLowerCase) {
        token = token.toLowerCase();
        if (stripAccents) {
          token = _runStripAccents(token);
        }
      } else if (stripAccents) {
        token = _runStripAccents(token);
      }
      splitTokens.addAll(_runSplitOnPunc(token));
    }
    return whitespaceTokenize(splitTokens.join(' '));
  }

  List<String> _runSplitOnPunc(String text) {
    final runes = text.runes.toList();
    var i = 0;
    var startNewWord = true;
    final output = <List<int>>[];
    while (i < runes.length) {
      final cp = runes[i];
      if (_isPunctuationRune(cp)) {
        output.add([cp]);
        startNewWord = true;
      } else {
        if (startNewWord) {
          output.add([]);
        }
        startNewWord = false;
        output.last.add(cp);
      }
      i++;
    }
    return output
        .map((r) => String.fromCharCodes(r))
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class BertWordpieceTokenizer {
  BertWordpieceTokenizer({
    required this.vocab,
    required this.unkToken,
    this.maxInputCharsPerWord = 100,
  });

  final Map<String, int> vocab;
  final String unkToken;
  final int maxInputCharsPerWord;

  List<String> tokenize(String text) {
    final outputTokens = <String>[];
    for (final token in whitespaceTokenize(text)) {
      final runes = token.runes.toList();
      if (runes.length > maxInputCharsPerWord) {
        outputTokens.add(unkToken);
        continue;
      }
      var isBad = false;
      var start = 0;
      final subTokens = <String>[];
      while (start < runes.length) {
        var end = runes.length;
        String? curSubstr;
        while (start < end) {
          var substr = String.fromCharCodes(runes.sublist(start, end));
          if (start > 0) {
            substr = '##$substr';
          }
          if (vocab.containsKey(substr)) {
            curSubstr = substr;
            break;
          }
          end--;
        }
        if (curSubstr == null) {
          isBad = true;
          break;
        }
        subTokens.add(curSubstr);
        start = end;
      }
      if (isBad) {
        outputTokens.add(unkToken);
      } else {
        outputTokens.addAll(subTokens);
      }
    }
    return outputTokens;
  }
}

/// MiniLM / BERT uncased tokenizer: tokenize + build [CLS] ... [SEP] + pad.
class BertTokenizerForMiniLm {
  BertTokenizerForMiniLm({
    required this.vocab,
    required this.unkToken,
    required this.clsToken,
    required this.sepToken,
    required this.padToken,
  })  : unkId = vocab[unkToken] ?? 100,
        clsId = vocab['[CLS]'] ?? 101,
        sepId = vocab['[SEP]'] ?? 102,
        padId = vocab['[PAD]'] ?? 0 {
    basic = BertBasicTokenizer();
    wordpiece = BertWordpieceTokenizer(vocab: vocab, unkToken: unkToken);
  }

  final Map<String, int> vocab;
  final String unkToken;
  final String clsToken;
  final String sepToken;
  final String padToken;
  final int unkId;
  final int clsId;
  final int sepId;
  final int padId;

  late final BertBasicTokenizer basic;
  late final BertWordpieceTokenizer wordpiece;

  List<String> _tokenize(String text) {
    final splitTokens = <String>[];
    for (final token in basic.tokenize(text)) {
      splitTokens.addAll(wordpiece.tokenize(token));
    }
    return splitTokens;
  }

  int _convertTokenToId(String token) => vocab[token] ?? unkId;

  /// Returns input_ids and attention_mask (length [maxLen]).
  ({List<int> inputIds, List<int> attentionMask}) encodePlus({
    required String text,
    int maxLen = 128,
  }) {
    final tokens = _tokenize(text);
    var ids = tokens.map(_convertTokenToId).toList();
    if (ids.length > maxLen - 2) {
      ids = ids.sublist(0, maxLen - 2);
    }
    final out = <int>[clsId, ...ids, sepId];
    final mask = List<int>.filled(maxLen, 0);
    final padded = List<int>.filled(maxLen, padId);
    for (var i = 0; i < out.length && i < maxLen; i++) {
      padded[i] = out[i];
      mask[i] = 1;
    }
    return (inputIds: padded, attentionMask: mask);
  }
}

/// Sentence-Transformer mean pooling + L2 norm (dim [hiddenSize]).
Float32List meanNormalizeSentenceEmbedding({
  required List<List<List<double>>> batch, // [1, seq, hidden]
  required List<int> attentionMask,
  required int hiddenSize,
}) {
  final seq = batch[0];
  final sum = Float32List(hiddenSize);
  var denom = 0.0;
  for (var i = 0; i < seq.length && i < attentionMask.length; i++) {
    if (attentionMask[i] == 0) continue;
    denom += 1;
    final row = seq[i];
    for (var j = 0; j < hiddenSize && j < row.length; j++) {
      sum[j] += row[j];
    }
  }
  if (denom < 1e-9) {
    return sum;
  }
  for (var j = 0; j < hiddenSize; j++) {
    sum[j] /= denom;
  }
  var n = 0.0;
  for (var j = 0; j < hiddenSize; j++) {
    n += sum[j] * sum[j];
  }
  n = math.sqrt(n);
  if (n < 1e-9) return sum;
  for (var j = 0; j < hiddenSize; j++) {
    sum[j] /= n;
  }
  return sum;
}
