// Port of langchain_text_splitters RecursiveCharacterTextSplitter
// to match server/embedding_service.py (_chunk_text).

/// Same defaults as [server/embedding_service.py] `_chunk_text`.
List<String> defaultEmbeddingSeparators() => [
      '\n\n',
      '\n',
      '. ',
      '! ',
      '? ',
      '; ',
      ': ',
      ', ',
      ' ',
      '',
    ];

/// Like Python `re.split` with a capturing group (includes delimiters).
List<String> _reSplitCapturing(String text, String innerPattern) {
  if (innerPattern.isEmpty) {
    return text.split('');
  }
  final pattern = RegExp('($innerPattern)');
  final splits_ = <String>[];
  var start = 0;
  for (final m in pattern.allMatches(text)) {
    if (m.start > start) {
      splits_.add(text.substring(start, m.start));
    }
    splits_.add(m.group(0)!);
    start = m.end;
  }
  if (start < text.length) {
    splits_.add(text.substring(start));
  }
  return splits_;
}

/// Mirrors LangChain `_split_text_with_regex` with `keep_separator=True` (bool).
/// [escapedPattern] matches Python `re.escape(separator)` for that separator.
List<String> splitTextWithRegex(String text, String escapedPattern, bool keepSeparator) {
  if (escapedPattern.isEmpty) {
    return text.split('');
  }
  final splits_ = _reSplitCapturing(text, escapedPattern);
  if (!keepSeparator) {
    return splits_.where((s) => s.isNotEmpty).toList();
  }
  final mid = <String>[];
  for (var i = 1; i < splits_.length; i += 2) {
    if (i + 1 < splits_.length) {
      mid.add(splits_[i] + splits_[i + 1]);
    }
  }
  if (splits_.length % 2 == 0) {
    mid.add(splits_.last);
  }
  return [splits_.first, ...mid];
}

/// Recursive character splitter matching LangChain / server embedding chunking.
class RecursiveCharacterTextSplitter {
  RecursiveCharacterTextSplitter({
    this.chunkSize = 700,
    this.chunkOverlap = 120,
    List<String>? separators,
    this.keepSeparator = true,
    this.isSeparatorRegex = false,
  })  : separators = separators ?? defaultEmbeddingSeparators() {
    if (chunkOverlap >= chunkSize) {
      throw ArgumentError('chunk_overlap must be < chunk_size');
    }
  }

  final int chunkSize;
  final int chunkOverlap;
  final List<String> separators;
  final bool keepSeparator;
  final bool isSeparatorRegex;

  int _len(String s) => s.length;

  String? _joinDocs(List<String> docs, String separator) {
    var text = docs.join(separator);
    text = text.trim();
    return text.isEmpty ? null : text;
  }

  List<String> _mergeSplits(Iterable<String> splits, String separator) {
    final separatorLen = _len(separator);
    final docs = <String>[];
    var currentDoc = <String>[];
    var total = 0;
    for (final d in splits) {
      final lenD = _len(d);
      if (total + lenD + (currentDoc.isNotEmpty ? separatorLen : 0) > chunkSize) {
        if (currentDoc.isNotEmpty) {
          final doc = _joinDocs(currentDoc, separator);
          if (doc != null) docs.add(doc);
          while (total > chunkOverlap ||
              (total + lenD + (currentDoc.isNotEmpty ? separatorLen : 0) > chunkSize &&
                  total > 0)) {
            total -= _len(currentDoc[0]) +
                (currentDoc.length > 1 ? separatorLen : 0);
            currentDoc = currentDoc.sublist(1);
          }
        }
      }
      currentDoc.add(d);
      total += lenD + (currentDoc.length > 1 ? separatorLen : 0);
    }
    final doc = _joinDocs(currentDoc, separator);
    if (doc != null) docs.add(doc);
    return docs;
  }

  List<String> _splitText(String text, List<String> sepList) {
    final finalChunks = <String>[];
    var separator = sepList.last;
    var newSeparators = <String>[];
    for (var i = 0; i < sepList.length; i++) {
      final s = sepList[i];
      if (s.isEmpty) {
        separator = s;
        break;
      }
      final pattern =
          isSeparatorRegex ? RegExp(s) : RegExp(RegExp.escape(s));
      if (pattern.hasMatch(text)) {
        separator = s;
        newSeparators = sepList.sublist(i + 1);
        break;
      }
    }
    final sepPattern = isSeparatorRegex ? separator : RegExp.escape(separator);
    final splits = splitTextWithRegex(
      text,
      sepPattern,
      keepSeparator,
    );
    final sepForMerge = keepSeparator ? '' : separator;
    var goodSplits = <String>[];
    for (final s in splits) {
      if (_len(s) < chunkSize) {
        goodSplits.add(s);
      } else {
        if (goodSplits.isNotEmpty) {
          final merged = _mergeSplits(goodSplits, sepForMerge);
          finalChunks.addAll(merged);
          goodSplits = [];
        }
        if (newSeparators.isEmpty) {
          finalChunks.add(s);
        } else {
          finalChunks.addAll(_splitText(s, newSeparators));
        }
      }
    }
    if (goodSplits.isNotEmpty) {
      final merged = _mergeSplits(goodSplits, sepForMerge);
      finalChunks.addAll(merged);
    }
    return finalChunks;
  }

  /// Public API matching LangChain `split_text`.
  List<String> splitText(String text) => _splitText(text, separators);
}
