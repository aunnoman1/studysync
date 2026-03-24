import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/drive_auth_service.dart';
import '../services/drive_sync_service.dart';
import '../theme.dart';

class DriveSyncSettingsPage extends StatefulWidget {
  final DriveAuthService authService;
  final DriveSyncService syncService;
  final VoidCallback? onSyncCompleted;

  const DriveSyncSettingsPage({
    super.key,
    required this.authService,
    required this.syncService,
    this.onSyncCompleted,
  });

  @override
  State<DriveSyncSettingsPage> createState() => _DriveSyncSettingsPageState();
}

class _DriveSyncSettingsPageState extends State<DriveSyncSettingsPage> {
  DriveAuthState _auth = const DriveAuthState(
    isConnected: false,
    email: null,
    displayName: null,
  );
  bool _busy = false;
  String? _status;
  DriveSyncDiagnostics? _diagnostics;

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  Future<void> _refreshState() async {
    final auth = await widget.authService.getState();
    DriveSyncDiagnostics? diagnostics;
    if (auth.isConnected && kDebugMode) {
      diagnostics = await widget.syncService.getDiagnostics();
    }
    if (!mounted) return;
    setState(() {
      _auth = auth;
      _diagnostics = diagnostics;
    });
  }

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final connected = await widget.authService.connect();
      if (!mounted) return;
      if (connected == null) {
        setState(() => _status = 'Drive connection cancelled.');
      } else {
        setState(() => _status = 'Connected: ${connected.email}');
      }
      await _refreshState();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Connection failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      await widget.authService.disconnect();
      if (!mounted) return;
      setState(() => _status = 'Disconnected from Google Drive.');
      await _refreshState();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Disconnect failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _debugDownloadLatest() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final b64 = await widget.syncService.exportLatestRemoteFileForDebug();
      if (!mounted) return;
      if (b64 == null) {
        setState(() => _status = 'No remote backups found in appDataFolder.');
      } else {
        setState(
          () => _status =
              'Debug downloaded latest backup (base64 length: ${b64.length}).',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Debug download failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cloud Sync',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Google Drive (scoped app storage)',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _auth.isConnected
                      ? 'Connected as ${_auth.email}'
                      : 'Not connected. Local notes continue working without cloud sync.',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _busy || _auth.isConnected ? null : _connect,
                      icon: const Icon(Icons.link),
                      label: const Text('Connect'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy || !_auth.isConnected
                          ? null
                          : _disconnect,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 12),
            Text(
              _status!,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
          if (kDebugMode && _auth.isConnected) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debug Diagnostics',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Remote backup files: ${_diagnostics?.remoteFileCount ?? 0}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  Text(
                    'Latest remote modified: ${_diagnostics?.latestRemoteModifiedTime?.toLocal() ?? '-'}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _debugDownloadLatest,
                    icon: const Icon(Icons.download_for_offline_outlined),
                    label: const Text('Debug Download Latest Backup'),
                  ),
                  const SizedBox(height: 8),
                  ...?_diagnostics?.remoteFiles
                      .take(10)
                      .map(
                        (f) => Text(
                          '- ${f.name} (${f.id})',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
