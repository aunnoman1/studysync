import 'dart:convert';
import 'dart:typed_data';

import 'note_transfer_models.dart';

class NoteArchiveCodec {
  static const int schemaVersion = 1;

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
    if (archive.schemaVersion != schemaVersion) {
      throw FormatException(
        'Unsupported archive schema version: ${archive.schemaVersion}',
      );
    }
    return archive;
  }
}
