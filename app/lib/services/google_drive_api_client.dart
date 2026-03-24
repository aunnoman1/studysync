import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

class DriveStoredFile {
  final String id;
  final String name;
  final DateTime? modifiedTime;

  const DriveStoredFile({
    required this.id,
    required this.name,
    required this.modifiedTime,
  });
}

class GoogleDriveApiClient {
  static const String _mimeType = 'application/x-studysync-note';

  drive.DriveApi _api(AuthClient client) =>
      drive.DriveApi(client as http.Client);

  Future<List<DriveStoredFile>> listNoteFiles(AuthClient client) async {
    final res = await _api(client).files.list(
      spaces: 'appDataFolder',
      q: "mimeType='$_mimeType' and trashed=false",
      $fields: 'files(id,name,modifiedTime)',
      pageSize: 1000,
    );
    final files = res.files ?? const <drive.File>[];
    return files
        .where((f) => f.id != null && f.name != null)
        .map(
          (f) => DriveStoredFile(
            id: f.id!,
            name: f.name!,
            modifiedTime: f.modifiedTime,
          ),
        )
        .toList();
  }

  Future<String> uploadNewFile({
    required AuthClient client,
    required String filename,
    required Uint8List bytes,
  }) async {
    final fileMeta = drive.File()
      ..name = filename
      ..mimeType = _mimeType
      ..parents = <String>['appDataFolder'];
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final created = await _api(
      client,
    ).files.create(fileMeta, uploadMedia: media);
    if (created.id == null) {
      throw const FormatException('Drive file create failed: missing id');
    }
    return created.id!;
  }

  Future<void> updateFile({
    required AuthClient client,
    required String fileId,
    required Uint8List bytes,
    String? filename,
  }) async {
    final fileMeta = drive.File();
    if (filename != null && filename.isNotEmpty) fileMeta.name = filename;
    final media = drive.Media(Stream.value(bytes), bytes.length);
    await _api(client).files.update(fileMeta, fileId, uploadMedia: media);
  }

  Future<void> deleteFile({
    required AuthClient client,
    required String fileId,
  }) async {
    await _api(client).files.delete(fileId);
  }

  Future<Uint8List> downloadFile({
    required AuthClient client,
    required String fileId,
  }) async {
    final media =
        await _api(client).files.get(
              fileId,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final chunks = <int>[];
    await for (final c in media.stream) {
      chunks.addAll(c);
    }
    return Uint8List.fromList(chunks);
  }

  String buildRemoteFilename(String title, int noteId) {
    final safe = sanitizeTitle(title);
    final base = safe.isEmpty ? 'note' : safe;
    return 'note-$noteId-$base.studysync';
  }

  String sanitizeTitle(String title) {
    return title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^[-_.]+|[-_.]+$'), '');
  }

  String? parseSanitizedTitleFromFilename(String filename) {
    final match = RegExp(r'^note-\d+-(.+)\.studysync$').firstMatch(filename);
    if (match == null) return null;
    final parsed = match.group(1);
    if (parsed == null || parsed.isEmpty) return null;
    return parsed;
  }

  String buildMappingStorageKey(String email) =>
      'drive_sync_mapping_${base64Url.encode(utf8.encode(email))}';
}
