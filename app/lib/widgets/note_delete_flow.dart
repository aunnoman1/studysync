import 'package:flutter/material.dart';

import '../models/note_record.dart';
import '../services/drive_sync_service.dart';
import '../theme.dart';

/// Layout matches [MyNotesPage] compact breakpoint.
const double kNoteDeleteCompactBreakpoint = 600;

class NoteDeleteFlow {
  NoteDeleteFlow._();

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < kNoteDeleteCompactBreakpoint;

  /// Shows the same delete UX as My Notes: local-only vs cloud-only confirm,
  /// or synced three-option sheet.
  ///
  /// [runAsync] wraps async work (e.g. sync busy flag). Sync [void] delete
  /// for local-only can omit it.
  static Future<void> showForRow(
    BuildContext context, {
    required NoteSyncStatusRow row,
    required bool driveConnected,
    required void Function(NoteRecord) onDeleteLocalFull,
    required Future<void> Function(String driveFileId) onDeleteDriveFile,
    required Future<void> Function(NoteRecord) onDeleteLocalCopy,
    required Future<void> Function(NoteRecord, String) onDeleteSyncedBoth,
    Future<void> Function(Future<void> Function() action)? runAsync,
  }) async {
    Future<void> run(Future<void> Function() action) async {
      if (runAsync != null) {
        await runAsync(action);
      } else {
        await action();
      }
    }

    switch (row.state) {
      case NoteCloudState.localOnly:
        final local = row.localNote;
        if (local == null) return;
        final ok = await _confirmAdaptive(
          context,
          title: 'Delete note?',
          message:
              '"${local.title}" exists only on this device. Deleting removes it from this app and cannot be undone.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (ok == true && context.mounted) {
          onDeleteLocalFull(local);
        }
        break;
      case NoteCloudState.driveOnly:
        final id = row.driveFile?.id;
        if (id == null || id.isEmpty) return;
        final ok = await _confirmAdaptive(
          context,
          title: 'Delete cloud copy?',
          message:
              '"${row.displayTitle}" exists only in Google Drive (app data). Deleting removes the cloud backup permanently.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (ok != true || !context.mounted) return;
        if (!driveConnected) return;
        await run(() => onDeleteDriveFile(id));
        break;
      case NoteCloudState.synced:
        final local = row.localNote;
        final driveId = row.driveFile?.id;
        if (local == null || driveId == null || driveId.isEmpty) return;
        await _showSyncedDelete(
          context,
          row: row,
          driveConnected: driveConnected,
          onDeleteLocalCopy: () => onDeleteLocalCopy(local),
          onDeleteDriveFile: () => onDeleteDriveFile(driveId),
          onDeleteSyncedBoth: () => onDeleteSyncedBoth(local, driveId),
          run: run,
        );
        break;
    }
  }

  static Future<bool?> _confirmAdaptive(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required bool destructive,
  }) {
    final compact = isCompact(context);
    if (compact) {
      return showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: destructive
                              ? const Color(0xFFEF4444)
                              : AppTheme.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(confirmLabel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  destructive ? const Color(0xFFEF4444) : AppTheme.blue,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  static Future<void> _showSyncedDelete(
    BuildContext context, {
    required NoteSyncStatusRow row,
    required bool driveConnected,
    required Future<void> Function() onDeleteLocalCopy,
    required Future<void> Function() onDeleteDriveFile,
    required Future<void> Function() onDeleteSyncedBoth,
    required Future<void> Function(Future<void> Function() action) run,
  }) async {
    final compact = isCompact(context);

    if (compact) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 20 + MediaQuery.viewInsetsOf(ctx).bottom,
              top: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Delete synced note',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '"${row.displayTitle}" exists on this device and in Google Drive. Choose what to delete.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await run(onDeleteLocalCopy);
                  },
                  child: const Text('Delete local copy only'),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: !driveConnected
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await run(onDeleteDriveFile);
                        },
                  child: const Text('Delete cloud copy only'),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: !driveConnected
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await run(onDeleteSyncedBoth);
                        },
                  child: const Text('Delete both'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete synced note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '"${row.displayTitle}" exists on this device and in Google Drive. Choose what to delete.',
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await run(onDeleteLocalCopy);
                },
                child: const Text('Delete local copy only'),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: !driveConnected
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await run(onDeleteDriveFile);
                      },
                child: const Text('Delete cloud copy only'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                ),
                onPressed: !driveConnected
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await run(onDeleteSyncedBoth);
                      },
                child: const Text('Delete both'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
