import 'dart:convert';

import '../models/note_record.dart';
import '../objectbox.dart';
import 'drive_auth_service.dart';
import 'drive_sync_state_store.dart';
import 'google_drive_api_client.dart';
import 'note_transfer_service.dart';

enum NoteCloudState { synced, localOnly, driveOnly }

class NoteSyncStatusRow {
  final String key;
  final String displayTitle;
  final NoteCloudState state;
  final NoteRecord? localNote;
  final DriveStoredFile? driveFile;
  final DateTime? latestTimestamp;
  final bool conflictResolved;

  const NoteSyncStatusRow({
    required this.key,
    required this.displayTitle,
    required this.state,
    required this.localNote,
    required this.driveFile,
    required this.latestTimestamp,
    required this.conflictResolved,
  });
}

class NoteRefreshResult {
  final List<NoteSyncStatusRow> rows;
  final int syncedCount;
  final int localOnlyCount;
  final int driveOnlyCount;
  final int conflictResolvedCount;

  const NoteRefreshResult({
    required this.rows,
    required this.syncedCount,
    required this.localOnlyCount,
    required this.driveOnlyCount,
    required this.conflictResolvedCount,
  });
}

class DriveSyncDiagnostics {
  final int remoteFileCount;
  final List<DriveStoredFile> remoteFiles;
  final DateTime? latestRemoteModifiedTime;

  const DriveSyncDiagnostics({
    required this.remoteFileCount,
    required this.remoteFiles,
    required this.latestRemoteModifiedTime,
  });
}

class DriveSyncSummary {
  final int uploaded;
  final int downloaded;
  final int unchanged;
  final int failed;
  final DateTime completedAt;

  const DriveSyncSummary({
    required this.uploaded,
    required this.downloaded,
    required this.unchanged,
    required this.failed,
    required this.completedAt,
  });
}

class DriveSyncService {
  final ObjectBox db;
  final DriveAuthService authService;
  final GoogleDriveApiClient apiClient;
  final DriveSyncStateStore stateStore;
  final NoteTransferService transferService;

  DriveSyncService({
    required this.db,
    required this.authService,
    GoogleDriveApiClient? apiClient,
    DriveSyncStateStore? stateStore,
    NoteTransferService? transferService,
  }) : apiClient = apiClient ?? GoogleDriveApiClient(),
       stateStore = stateStore ?? DriveSyncStateStore(),
       transferService = transferService ?? NoteTransferService(db: db);

  Future<NoteRefreshResult> refreshIndex() async {
    final auth = await authService.getState();
    if (!auth.isConnected || auth.email == null) {
      throw StateError('Google Drive is not connected.');
    }

    final client = await authService.getAuthenticatedClient();
    if (client == null) {
      throw StateError('Unable to authenticate with Google Drive.');
    }

    int conflictResolvedCount = 0;
    final stateKey = apiClient.buildMappingStorageKey(auth.email!);
    final mapping = await stateStore.load(stateKey);
    final rows = await _buildRowsWithReconcile(client, mapping);
    await stateStore.save(stateKey, mapping);
    client.close();

    int synced = 0;
    int localOnly = 0;
    int driveOnly = 0;
    for (final row in rows) {
      if (row.conflictResolved) conflictResolvedCount++;
      switch (row.state) {
        case NoteCloudState.synced:
          synced++;
          break;
        case NoteCloudState.localOnly:
          localOnly++;
          break;
        case NoteCloudState.driveOnly:
          driveOnly++;
          break;
      }
    }
    return NoteRefreshResult(
      rows: rows,
      syncedCount: synced,
      localOnlyCount: localOnly,
      driveOnlyCount: driveOnly,
      conflictResolvedCount: conflictResolvedCount,
    );
  }

  Future<DriveSyncSummary> uploadAllLocalOnly() async {
    final refresh = await refreshIndex();
    int uploaded = 0;
    int failed = 0;
    for (final row in refresh.rows.where(
      (r) => r.state == NoteCloudState.localOnly,
    )) {
      try {
        await uploadLocalNote(row.localNote!.id);
        uploaded++;
      } catch (_) {
        failed++;
      }
    }
    return DriveSyncSummary(
      uploaded: uploaded,
      downloaded: 0,
      unchanged: 0,
      failed: failed,
      completedAt: DateTime.now(),
    );
  }

  Future<DriveSyncSummary> downloadAllDriveOnly() async {
    final refresh = await refreshIndex();
    int downloaded = 0;
    int failed = 0;
    for (final row in refresh.rows.where(
      (r) => r.state == NoteCloudState.driveOnly,
    )) {
      try {
        await downloadDriveOnlyNote(row.driveFile!.id);
        downloaded++;
      } catch (_) {
        failed++;
      }
    }
    return DriveSyncSummary(
      uploaded: 0,
      downloaded: downloaded,
      unchanged: 0,
      failed: failed,
      completedAt: DateTime.now(),
    );
  }

  Future<void> uploadLocalNote(int localNoteId) async {
    final auth = await authService.getState();
    if (!auth.isConnected || auth.email == null) {
      throw StateError('Google Drive is not connected.');
    }
    final client = await authService.getAuthenticatedClient();
    if (client == null) {
      throw StateError('Unable to authenticate with Google Drive.');
    }
    final note = db.noteBox.get(localNoteId);
    if (note == null) throw StateError('Local note not found.');

    final remotes = await apiClient.listNoteFiles(client);
    final key = apiClient.sanitizeTitle(note.title);
    final existing = remotes.firstWhere(
      (f) => apiClient.parseSanitizedTitleFromFilename(f.name) == key,
      orElse: () => const DriveStoredFile(id: '', name: '', modifiedTime: null),
    );
    final bytes = transferService.exportNotesToBytes(<int>[localNoteId]);
    if (existing.id.isEmpty) {
      await apiClient.uploadNewFile(
        client: client,
        filename: apiClient.buildRemoteFilename(note.title, note.id),
        bytes: bytes,
      );
    } else {
      await apiClient.updateFile(
        client: client,
        fileId: existing.id,
        filename: apiClient.buildRemoteFilename(note.title, note.id),
        bytes: bytes,
      );
    }
    client.close();
  }

  Future<void> downloadDriveOnlyNote(String driveFileId) async {
    final auth = await authService.getState();
    if (!auth.isConnected) {
      throw StateError('Google Drive is not connected.');
    }
    final client = await authService.getAuthenticatedClient();
    if (client == null) {
      throw StateError('Unable to authenticate with Google Drive.');
    }
    final bytes = await apiClient.downloadFile(
      client: client,
      fileId: driveFileId,
    );
    transferService.importFromBytes(bytes);
    client.close();
  }

  Future<void> deleteLocalCopy(int localNoteId) async {
    transferService.deleteNoteTree(localNoteId);
    final auth = await authService.getState();
    if (auth.email == null) return;
    final key = apiClient.buildMappingStorageKey(auth.email!);
    final map = await stateStore.load(key);
    map.remove(localNoteId);
    await stateStore.save(key, map);
  }

  /// Permanently removes the backup file from Drive appDataFolder and drops
  /// any sync mapping entries pointing at [driveFileId].
  Future<void> deleteDriveFile(String driveFileId) async {
    final auth = await authService.getState();
    if (!auth.isConnected || auth.email == null) {
      throw StateError('Google Drive is not connected.');
    }
    final client = await authService.getAuthenticatedClient();
    if (client == null) {
      throw StateError('Unable to authenticate with Google Drive.');
    }
    await apiClient.deleteFile(client: client, fileId: driveFileId);
    client.close();

    final key = apiClient.buildMappingStorageKey(auth.email!);
    final map = await stateStore.load(key);
    map.removeWhere((_, v) => v.remoteFileId == driveFileId);
    await stateStore.save(key, map);
  }

  /// Removes the local note and the Drive backup for the same title.
  Future<void> deleteSyncedBoth(int localNoteId, String driveFileId) async {
    await deleteLocalCopy(localNoteId);
    await deleteDriveFile(driveFileId);
  }

  Future<NoteRecord?> _replaceLocalFromRemoteByTitle({
    required String titleKey,
    required String remoteFileId,
  }) async {
    final local = db.noteBox
        .getAll()
        .where((n) => apiClient.sanitizeTitle(n.title) == titleKey)
        .toList();
    for (final n in local) {
      transferService.deleteNoteTree(n.id);
    }
    final auth = await authService.getState();
    if (!auth.isConnected) return null;
    final client = await authService.getAuthenticatedClient();
    if (client == null) return null;
    final bytes = await apiClient.downloadFile(
      client: client,
      fileId: remoteFileId,
    );
    final before = db.noteBox.getAll().map((e) => e.id).toSet();
    transferService.importFromBytes(bytes);
    final after = db.noteBox.getAll();
    client.close();
    for (final n in after) {
      if (!before.contains(n.id)) return n;
    }
    return null;
  }

  Future<List<NoteSyncStatusRow>> _buildRowsWithReconcile(
    dynamic client,
    Map<int, DriveSyncNoteState> mapping,
  ) async {
    final localNotes = db.noteBox.getAll();
    final localByKey = <String, NoteRecord>{};
    for (final n in localNotes) {
      final key = apiClient.sanitizeTitle(n.title);
      final existing = localByKey[key];
      if (existing == null || n.updatedAt.isAfter(existing.updatedAt)) {
        localByKey[key] = n;
      }
    }

    final remoteFiles = await apiClient.listNoteFiles(client);
    final remoteByKey = <String, DriveStoredFile>{};
    for (final f in remoteFiles) {
      final key = apiClient.parseSanitizedTitleFromFilename(f.name);
      if (key == null) continue;
      final existing = remoteByKey[key];
      final currentTs =
          f.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final existingTs =
          existing?.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (existing == null || currentTs.isAfter(existingTs)) {
        remoteByKey[key] = f;
      }
    }

    final allKeys = <String>{...localByKey.keys, ...remoteByKey.keys}.toList()
      ..sort();
    final rows = <NoteSyncStatusRow>[];

    for (final key in allKeys) {
      final local = localByKey[key];
      final remote = remoteByKey[key];
      bool conflictResolved = false;

      if (local != null && remote != null) {
        final localTs = local.updatedAt.toUtc();
        final remoteTs =
            (remote.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0))
                .toUtc();
        if (localTs.isAfter(remoteTs)) {
          final bytes = transferService.exportNotesToBytes(<int>[local.id]);
          await apiClient.updateFile(
            client: client,
            fileId: remote.id,
            filename: apiClient.buildRemoteFilename(local.title, local.id),
            bytes: bytes,
          );
          conflictResolved = true;
        } else if (remoteTs.isAfter(localTs)) {
          final replaced = await _replaceLocalFromRemoteByTitle(
            titleKey: key,
            remoteFileId: remote.id,
          );
          if (replaced != null) {
            mapping[replaced.id] = DriveSyncNoteState(
              localNoteId: replaced.id,
              remoteFileId: remote.id,
              remoteModifiedTime: remote.modifiedTime?.toUtc(),
              lastSyncedAt: DateTime.now().toUtc(),
            );
            rows.add(
              NoteSyncStatusRow(
                key: key,
                displayTitle: replaced.title,
                state: NoteCloudState.synced,
                localNote: replaced,
                driveFile: remote,
                latestTimestamp: remote.modifiedTime,
                conflictResolved: true,
              ),
            );
            continue;
          }
        }
        mapping[local.id] = DriveSyncNoteState(
          localNoteId: local.id,
          remoteFileId: remote.id,
          remoteModifiedTime: remote.modifiedTime?.toUtc(),
          lastSyncedAt: DateTime.now().toUtc(),
        );
        rows.add(
          NoteSyncStatusRow(
            key: key,
            displayTitle: local.title,
            state: NoteCloudState.synced,
            localNote: local,
            driveFile: remote,
            latestTimestamp:
                local.updatedAt.isAfter(remote.modifiedTime ?? local.updatedAt)
                ? local.updatedAt
                : remote.modifiedTime,
            conflictResolved: conflictResolved,
          ),
        );
      } else if (local != null) {
        rows.add(
          NoteSyncStatusRow(
            key: key,
            displayTitle: local.title,
            state: NoteCloudState.localOnly,
            localNote: local,
            driveFile: null,
            latestTimestamp: local.updatedAt,
            conflictResolved: false,
          ),
        );
      } else if (remote != null) {
        rows.add(
          NoteSyncStatusRow(
            key: key,
            displayTitle: key.replaceAll('-', ' '),
            state: NoteCloudState.driveOnly,
            localNote: null,
            driveFile: remote,
            latestTimestamp: remote.modifiedTime,
            conflictResolved: false,
          ),
        );
      }
    }
    return rows;
  }

  Future<DriveSyncDiagnostics> getDiagnostics() async {
    final client = await authService.getAuthenticatedClient();
    if (client == null) {
      return const DriveSyncDiagnostics(
        remoteFileCount: 0,
        remoteFiles: <DriveStoredFile>[],
        latestRemoteModifiedTime: null,
      );
    }
    final files = await apiClient.listNoteFiles(client);
    DateTime? latest;
    for (final f in files) {
      final ts = f.modifiedTime;
      if (ts == null) continue;
      if (latest == null || ts.isAfter(latest)) latest = ts;
    }
    client.close();
    return DriveSyncDiagnostics(
      remoteFileCount: files.length,
      remoteFiles: files,
      latestRemoteModifiedTime: latest,
    );
  }

  Future<String?> exportLatestRemoteFileForDebug() async {
    final auth = await authService.getState();
    if (!auth.isConnected) return null;
    final client = await authService.getAuthenticatedClient();
    if (client == null) return null;
    final files = await apiClient.listNoteFiles(client);
    if (files.isEmpty) return null;
    files.sort((a, b) {
      final at = a.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bt = b.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bt.compareTo(at);
    });
    final latest = files.first;
    final bytes = await apiClient.downloadFile(
      client: client,
      fileId: latest.id,
    );
    client.close();
    return base64Encode(bytes);
  }
}
