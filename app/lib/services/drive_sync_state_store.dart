import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DriveSyncNoteState {
  final int localNoteId;
  final String remoteFileId;
  final DateTime? remoteModifiedTime;
  final DateTime? lastSyncedAt;

  const DriveSyncNoteState({
    required this.localNoteId,
    required this.remoteFileId,
    required this.remoteModifiedTime,
    required this.lastSyncedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'localNoteId': localNoteId,
      'remoteFileId': remoteFileId,
      'remoteModifiedTime': remoteModifiedTime?.toUtc().toIso8601String(),
      'lastSyncedAt': lastSyncedAt?.toUtc().toIso8601String(),
    };
  }

  static DriveSyncNoteState fromJson(Map<String, dynamic> json) {
    return DriveSyncNoteState(
      localNoteId: (json['localNoteId'] as num?)?.toInt() ?? 0,
      remoteFileId: (json['remoteFileId'] as String?) ?? '',
      remoteModifiedTime: DateTime.tryParse(
        (json['remoteModifiedTime'] as String?) ?? '',
      ),
      lastSyncedAt: DateTime.tryParse((json['lastSyncedAt'] as String?) ?? ''),
    );
  }
}

class DriveSyncStateStore {
  Future<Map<int, DriveSyncNoteState>> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <int, DriveSyncNoteState>{};

    final data = jsonDecode(raw);
    if (data is! List<dynamic>) return <int, DriveSyncNoteState>{};

    final map = <int, DriveSyncNoteState>{};
    for (final e in data.whereType<Map<String, dynamic>>()) {
      final item = DriveSyncNoteState.fromJson(e);
      if (item.localNoteId > 0 && item.remoteFileId.isNotEmpty) {
        map[item.localNoteId] = item;
      }
    }
    return map;
  }

  Future<void> save(String key, Map<int, DriveSyncNoteState> state) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = state.values.map((e) => e.toJson()).toList();
    await prefs.setString(key, jsonEncode(payload));
  }

  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
