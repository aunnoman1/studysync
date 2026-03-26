import 'dart:convert';
import 'dart:typed_data';

import 'note_transfer_models.dart';

class NoteArchiveCodec {
  /// Schema version 1: initial format (no diagrams).
  /// Schema version 2: added diagram data per image.
  static const int schemaVersion = 2;

  Uint8List encode(NoteExportArchive archive) {
    final jsonMap = archive.toJson();
    return Uint8List.fromList(utf8.encode(jsonEncode(jsonMap)));
  }

  NoteExportArchive decode(Uint8List bytes) {
    final dynamic data = jsonDecode(utf8.decode(bytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid archive: expected JSON object.');
    }
    final archive = NoteExportArchive.fromJson(data);
    // Accept v1 (no diagrams) and v2 (with diagrams) for backwards compat.
    if (archive.schemaVersion < 1 || archive.schemaVersion > schemaVersion) {
      throw FormatException(
        'Unsupported archive schema version: ${archive.schemaVersion}',
      );
    }
    return archive;
  }
}
