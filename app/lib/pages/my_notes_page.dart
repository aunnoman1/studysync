import 'package:flutter/material.dart';
import '../models/note_record.dart';
import '../services/drive_sync_service.dart';
import '../theme.dart';
import '../widgets/note_delete_flow.dart';

String _formatDate(DateTime dt) {
  final d = dt.toLocal();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Layout switches to a card list below this width (Material compact window).

class MyNotesPage extends StatefulWidget {
  final void Function() onCreateNew;
  final List<NoteRecord> capturedNotes;
  final void Function(NoteRecord note) onOpenCaptured;
  final void Function(NoteRecord note) onDeleteCaptured;
  final Future<void> Function(List<NoteRecord> selectedNotes) onExportSelected;
  final Future<void> Function() onImportNotes;
  final bool driveConnected;
  final List<NoteSyncStatusRow> syncRows;
  final Future<void> Function() onRefreshSync;
  final Future<void> Function() onUploadAllLocalOnly;
  final Future<void> Function() onDownloadAllDriveOnly;
  final Future<void> Function(NoteRecord note) onUploadLocalNote;
  final Future<void> Function(String driveFileId) onDownloadDriveOnlyNote;
  final Future<void> Function(NoteRecord note) onDeleteLocalCopy;
  final Future<void> Function(String driveFileId) onDeleteDriveFile;
  final Future<void> Function(NoteRecord note, String driveFileId)
      onDeleteSyncedBoth;

  const MyNotesPage({
    super.key,
    required this.onCreateNew,
    required this.capturedNotes,
    required this.onOpenCaptured,
    required this.onDeleteCaptured,
    required this.onExportSelected,
    required this.onImportNotes,
    required this.driveConnected,
    required this.syncRows,
    required this.onRefreshSync,
    required this.onUploadAllLocalOnly,
    required this.onDownloadAllDriveOnly,
    required this.onUploadLocalNote,
    required this.onDownloadDriveOnlyNote,
    required this.onDeleteLocalCopy,
    required this.onDeleteDriveFile,
    required this.onDeleteSyncedBoth,
  });

  @override
  State<MyNotesPage> createState() => _MyNotesPageState();
}

class _MyNotesPageState extends State<MyNotesPage> {
  String _searchQuery = '';
  bool _selectionMode = false;
  bool _isImporting = false;
  bool _isExporting = false;
  bool _isSyncBusy = false;
  final Set<int> _selectedNoteIds = <int>{};

  bool _isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < kNoteDeleteCompactBreakpoint;

  EdgeInsets _pagePadding(BuildContext context) {
    final compact = _isCompact(context);
    return EdgeInsets.fromLTRB(
      compact ? 12 : 16,
      compact ? 8 : 16,
      compact ? 12 : 16,
      compact ? 16 : 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = _isCompact(context);
    final filteredRows = widget.syncRows.where((row) {
      if (_searchQuery.isEmpty) return true;
      return row.displayTitle.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();

    final localOnlyCount = widget.syncRows
        .where((r) => r.state == NoteCloudState.localOnly)
        .length;
    final driveOnlyCount = widget.syncRows
        .where((r) => r.state == NoteCloudState.driveOnly)
        .length;

    return SingleChildScrollView(
      padding: _pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Notes',
            style: TextStyle(
              fontSize: compact ? 22 : 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(compact ? 14 : 12),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: compact ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildToolbar(
                  compact: compact,
                  localOnlyCount: localOnlyCount,
                  driveOnlyCount: driveOnlyCount,
                ),
                if (_selectionMode) ...[
                  SizedBox(height: compact ? 10 : 8),
                  _buildSelectionBar(compact: compact),
                ],
                SizedBox(height: compact ? 12 : 12),
                _buildSearchField(compact: compact),
                SizedBox(height: compact ? 12 : 12),
                if (filteredRows.isEmpty)
                  _buildEmptyState(compact: compact)
                else if (compact)
                  _buildCardList(filteredRows)
                else
                  _buildTable(filteredRows),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar({
    required bool compact,
    required int localOnlyCount,
    required int driveOnlyCount,
  }) {
    final syncDisabled = !widget.driveConnected || _isSyncBusy;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'All Notes',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: widget.onCreateNew,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('New'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ToolbarPill(
                  icon: Icons.download_rounded,
                  label: 'Import',
                  onPressed: _isImporting
                      ? null
                      : () async {
                          setState(() => _isImporting = true);
                          try {
                            await widget.onImportNotes();
                          } finally {
                            if (mounted) {
                              setState(() => _isImporting = false);
                            }
                          }
                        },
                ),
                _ToolbarPill(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  onPressed: syncDisabled
                      ? null
                      : () async {
                          setState(() => _isSyncBusy = true);
                          try {
                            await widget.onRefreshSync();
                          } finally {
                            if (mounted) {
                              setState(() => _isSyncBusy = false);
                            }
                          }
                        },
                ),
                _ToolbarPill(
                  icon: Icons.cloud_upload_outlined,
                  label: 'Upload all',
                  badge: localOnlyCount > 0 ? '$localOnlyCount' : null,
                  onPressed: syncDisabled || localOnlyCount == 0
                      ? null
                      : () async {
                          setState(() => _isSyncBusy = true);
                          try {
                            await widget.onUploadAllLocalOnly();
                          } finally {
                            if (mounted) {
                              setState(() => _isSyncBusy = false);
                            }
                          }
                        },
                ),
                _ToolbarPill(
                  icon: Icons.download_for_offline_outlined,
                  label: 'Get all',
                  badge: driveOnlyCount > 0 ? '$driveOnlyCount' : null,
                  onPressed: syncDisabled || driveOnlyCount == 0
                      ? null
                      : () async {
                          setState(() => _isSyncBusy = true);
                          try {
                            await widget.onDownloadAllDriveOnly();
                          } finally {
                            if (mounted) {
                              setState(() => _isSyncBusy = false);
                            }
                          }
                        },
                ),
                _ToolbarPill(
                  icon: Icons.upload_file_rounded,
                  label: 'Export',
                  onPressed: _selectionMode
                      ? null
                      : () {
                          setState(() {
                            _selectionMode = true;
                            _selectedNoteIds.clear();
                          });
                        },
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Text(
            'All Notes',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _isImporting
                    ? null
                    : () async {
                        setState(() => _isImporting = true);
                        try {
                          await widget.onImportNotes();
                        } finally {
                          if (mounted) {
                            setState(() => _isImporting = false);
                          }
                        }
                      },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Import'),
              ),
              OutlinedButton.icon(
                onPressed: syncDisabled
                    ? null
                    : () async {
                        setState(() => _isSyncBusy = true);
                        try {
                          await widget.onRefreshSync();
                        } finally {
                          if (mounted) {
                            setState(() => _isSyncBusy = false);
                          }
                        }
                      },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
              ),
              OutlinedButton.icon(
                onPressed: syncDisabled || localOnlyCount == 0
                    ? null
                    : () async {
                        setState(() => _isSyncBusy = true);
                        try {
                          await widget.onUploadAllLocalOnly();
                        } finally {
                          if (mounted) {
                            setState(() => _isSyncBusy = false);
                          }
                        }
                      },
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: Text('Upload all ($localOnlyCount)'),
              ),
              OutlinedButton.icon(
                onPressed: syncDisabled || driveOnlyCount == 0
                    ? null
                    : () async {
                        setState(() => _isSyncBusy = true);
                        try {
                          await widget.onDownloadAllDriveOnly();
                        } finally {
                          if (mounted) {
                            setState(() => _isSyncBusy = false);
                          }
                        }
                      },
                icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                label: Text('Download all ($driveOnlyCount)'),
              ),
              OutlinedButton.icon(
                onPressed: _selectionMode
                    ? null
                    : () {
                        setState(() {
                          _selectionMode = true;
                          _selectedNoteIds.clear();
                        });
                      },
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Export'),
              ),
              FilledButton.icon(
                onPressed: widget.onCreateNew,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add New'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionBar({required bool compact}) {
    return Material(
      color: AppTheme.blue.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 8 : 6,
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${_selectedNoteIds.length} selected',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isExporting
                              ? null
                              : () {
                                  setState(() {
                                    _selectionMode = false;
                                    _selectedNoteIds.clear();
                                  });
                                },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isExporting || _selectedNoteIds.isEmpty
                              ? null
                              : () async {
                                  setState(() => _isExporting = true);
                                  try {
                                    final selected = widget.capturedNotes
                                        .where(
                                          (n) => _selectedNoteIds.contains(
                                            n.id,
                                          ),
                                        )
                                        .toList();
                                    await widget.onExportSelected(selected);
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        _isExporting = false;
                                        _selectionMode = false;
                                        _selectedNoteIds.clear();
                                      });
                                    }
                                  }
                                },
                          child: Text(
                            _isExporting ? 'Exporting…' : 'Export selected',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedNoteIds.length} selected',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: _isExporting
                        ? null
                        : () {
                            setState(() {
                              _selectionMode = false;
                              _selectedNoteIds.clear();
                            });
                          },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: _isExporting || _selectedNoteIds.isEmpty
                        ? null
                        : () async {
                            setState(() => _isExporting = true);
                            try {
                              final selected = widget.capturedNotes
                                  .where(
                                    (n) => _selectedNoteIds.contains(n.id),
                                  )
                                  .toList();
                              await widget.onExportSelected(selected);
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isExporting = false;
                                  _selectionMode = false;
                                  _selectedNoteIds.clear();
                                });
                              }
                            }
                          },
                    child: Text(
                      _isExporting ? 'Exporting…' : 'Export selected',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchField({required bool compact}) {
    return TextField(
      onChanged: (val) {
        setState(() {
          _searchQuery = val.trim();
        });
      },
      decoration: InputDecoration(
        hintText: 'Search notes by title…',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppTheme.textSecondary,
        ),
        filled: true,
        fillColor: AppTheme.lightInputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.blue, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          vertical: compact ? 14 : 12,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState({required bool compact}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 28 : 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: compact ? 48 : 56,
              color: AppTheme.textSecondary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'No notes yet'
                  : 'No notes match your search',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Try a different title or clear the search',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(List<NoteSyncStatusRow> rows) {
    return Column(
      children: rows.map((row) => _NoteCard(
            row: row,
            selectionMode: _selectionMode,
            selected: row.localNote != null &&
                _selectedNoteIds.contains(row.localNote!.id),
            onRowTap: () => _handleRowTap(row),
            onToggleSelect: row.localNote == null
                ? null
                : () {
                    setState(() {
                      final id = row.localNote!.id;
                      if (_selectedNoteIds.contains(id)) {
                        _selectedNoteIds.remove(id);
                      } else {
                        _selectedNoteIds.add(id);
                      }
                    });
                  },
            rowActions: _buildRowActions(row, compact: true),
          )).toList(),
    );
  }

  void _handleRowTap(NoteSyncStatusRow row) {
    final local = row.localNote;
    if (local == null) return;
    if (_selectionMode) {
      setState(() {
        if (_selectedNoteIds.contains(local.id)) {
          _selectedNoteIds.remove(local.id);
        } else {
          _selectedNoteIds.add(local.id);
        }
      });
      return;
    }
    widget.onOpenCaptured(local);
  }

  Widget _buildTable(List<NoteSyncStatusRow> filteredRows) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                  bottom: BorderSide(color: AppTheme.border),
                ),
              ),
              child: const Row(
                children: [
                  _HeaderCell('', flex: 1),
                  _HeaderCell('Title', flex: 2),
                  _HeaderCell('Course'),
                  _HeaderCell('Date'),
                  SizedBox(width: 108),
                  SizedBox(width: 220),
                ],
              ),
            ),
            ...filteredRows.asMap().entries.map(
              (e) {
                final row = e.value;
                final isLast = e.key == filteredRows.length - 1;
                return InkWell(
                onTap: () => _handleRowTap(row),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(color: AppTheme.border),
                          ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _selectionMode
                          ? Checkbox(
                              value: row.localNote != null &&
                                  _selectedNoteIds.contains(
                                    row.localNote!.id,
                                  ),
                              onChanged: row.localNote == null
                                  ? null
                                  : (_) {
                                      setState(() {
                                        final id = row.localNote!.id;
                                        if (_selectedNoteIds.contains(id)) {
                                          _selectedNoteIds.remove(id);
                                        } else {
                                          _selectedNoteIds.add(id);
                                        }
                                      });
                                    },
                            )
                          : const SizedBox(width: 48),
                      _Cell(row.displayTitle, flex: 2),
                      _Cell(row.localNote?.course ?? '-'),
                      _Cell(
                        row.latestTimestamp == null
                            ? '-'
                            : _formatDate(row.latestTimestamp!),
                      ),
                      SizedBox(
                        width: 108,
                        child: _SyncChip(state: row.state, dense: false),
                      ),
                      SizedBox(
                        width: 220,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            alignment: WrapAlignment.end,
                            children: _buildRowActions(row, compact: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _withSyncBusy(Future<void> Function() action) async {
    setState(() => _isSyncBusy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isSyncBusy = false);
    }
  }

  Widget _deleteIconButton({required VoidCallback onPressed}) {
    return IconButton(
      tooltip: 'Delete',
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFFEF4444),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: _isSyncBusy ? null : onPressed,
      icon: const Icon(Icons.delete_outline_rounded),
    );
  }

  Future<void> _runDeleteFlowForRow(NoteSyncStatusRow row) async {
    await NoteDeleteFlow.showForRow(
      context,
      row: row,
      driveConnected: widget.driveConnected,
      onDeleteLocalFull: widget.onDeleteCaptured,
      onDeleteDriveFile: widget.onDeleteDriveFile,
      onDeleteLocalCopy: widget.onDeleteLocalCopy,
      onDeleteSyncedBoth: widget.onDeleteSyncedBoth,
      runAsync: _withSyncBusy,
    );
  }

  ButtonStyle _rowActionStyle(bool compact) {
    return OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 16,
        vertical: compact ? 10 : 12,
      ),
      minimumSize: compact ? const Size(0, 44) : null,
      tapTargetSize: MaterialTapTargetSize.padded,
      textStyle: TextStyle(fontSize: compact ? 13 : 14),
    );
  }

  List<Widget> _buildRowActions(NoteSyncStatusRow row, {required bool compact}) {
    switch (row.state) {
      case NoteCloudState.localOnly:
        if (row.localNote == null) return const [];
        return [
          OutlinedButton(
            style: _rowActionStyle(compact),
            onPressed: _isSyncBusy
                ? null
                : () async {
                    setState(() => _isSyncBusy = true);
                    try {
                      await widget.onUploadLocalNote(row.localNote!);
                    } finally {
                      if (mounted) setState(() => _isSyncBusy = false);
                    }
                  },
            child: Text(compact ? 'Sync' : 'Sync to Cloud'),
          ),
          _deleteIconButton(
            onPressed: () => _runDeleteFlowForRow(row),
          ),
        ];
      case NoteCloudState.driveOnly:
        if (row.driveFile == null) return const [];
        return [
          OutlinedButton(
            style: _rowActionStyle(compact),
            onPressed: _isSyncBusy
                ? null
                : () async {
                    setState(() => _isSyncBusy = true);
                    try {
                      await widget.onDownloadDriveOnlyNote(row.driveFile!.id);
                    } finally {
                      if (mounted) setState(() => _isSyncBusy = false);
                    }
                  },
            child: const Text('Download'),
          ),
          _deleteIconButton(
            onPressed: () => _runDeleteFlowForRow(row),
          ),
        ];
      case NoteCloudState.synced:
        if (row.localNote == null) return const [];
        return [
          _deleteIconButton(
            onPressed: () => _runDeleteFlowForRow(row),
          ),
        ];
    }
  }
}

/// Horizontally scrollable toolbar chip for narrow screens.
class _ToolbarPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? badge;

  const _ToolbarPill({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: label,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(0, 44),
            tapTargetSize: MaterialTapTargetSize.padded,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13)),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.blue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final NoteSyncStatusRow row;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onRowTap;
  final VoidCallback? onToggleSelect;
  final List<Widget> rowActions;

  const _NoteCard({
    required this.row,
    required this.selectionMode,
    required this.selected,
    required this.onRowTap,
    required this.onToggleSelect,
    required this.rowActions,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocal = row.localNote != null;
    final String subtitle;
    if (row.state == NoteCloudState.driveOnly) {
      subtitle = [
        'Cloud only — use Download to save here',
        if (row.latestTimestamp != null) _formatDate(row.latestTimestamp!),
      ].join(' · ');
    } else {
      subtitle = [
        if ((row.localNote?.course ?? '').trim().isNotEmpty)
          row.localNote!.course
        else
          'No course',
        if (row.latestTimestamp != null) _formatDate(row.latestTimestamp!),
      ].join(' · ');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected
                ? AppTheme.blue.withValues(alpha: 0.5)
                : AppTheme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: hasLocal ? onRowTap : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (selectionMode && onToggleSelect != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Checkbox(
                          value: selected,
                          onChanged: (_) => onToggleSelect!(),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.displayTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              height: 1.25,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.95,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _SyncChip(state: row.state, dense: true),
                  ],
                ),
                if (rowActions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 8,
                            alignment: WrapAlignment.end,
                            children: rowActions,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  const _Cell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SyncChip extends StatelessWidget {
  final NoteCloudState state;
  final bool dense;

  const _SyncChip({required this.state, this.dense = false});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color bg;
    late final Color fg;
    switch (state) {
      case NoteCloudState.synced:
        label = 'Synced';
        bg = const Color(0xFFD1FAE5);
        fg = const Color(0xFF047857);
        break;
      case NoteCloudState.localOnly:
        label = 'Local';
        bg = const Color(0xFFE0E7FF);
        fg = const Color(0xFF4338CA);
        break;
      case NoteCloudState.driveOnly:
        label = 'Cloud';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 4 : 5,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: dense ? 11 : 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
