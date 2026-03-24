import 'package:flutter/foundation.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart' as auth_io;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../env.dart';

class DriveAuthState {
  final bool isConnected;
  final String? email;
  final String? displayName;

  const DriveAuthState({
    required this.isConnected,
    required this.email,
    required this.displayName,
  });
}

class DriveAuthService {
  static const String _emailKey = 'drive_sync_email';
  static const String _nameKey = 'drive_sync_name';
  static const String _desktopCredsKey = 'drive_sync_desktop_credentials';
  static const List<String> _scopes = <String>[
    'https://www.googleapis.com/auth/drive.appdata',
    'email',
  ];

  late final GoogleSignIn _googleSignIn;

  DriveAuthService() {
    _googleSignIn = GoogleSignIn(
      scopes: _scopes,
      clientId: _resolveClientId(),
      serverClientId: Env.googleServerClientId,
    );
  }

  String? _resolveClientId() {
    if (kIsWeb) return Env.googleWebClientId;
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return Env.googleDesktopClientId;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return null;
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  Future<DriveAuthState> getState() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);
    final name = prefs.getString(_nameKey);
    final desktopCreds = prefs.getString(_desktopCredsKey);
    final isDesktopConnected = _useDesktopOAuth && desktopCreds != null;
    return DriveAuthState(
      isConnected: isDesktopConnected || (email != null && email.isNotEmpty),
      email: email,
      displayName: name,
    );
  }

  Future<DriveAuthState?> connect() async {
    if (_useDesktopOAuth) {
      return _connectDesktopOAuth();
    }
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, account.email);
    await prefs.setString(_nameKey, account.displayName ?? '');
    return DriveAuthState(
      isConnected: true,
      email: account.email,
      displayName: account.displayName,
    );
  }

  Future<void> disconnect() async {
    if (_useDesktopOAuth) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_desktopCredsKey);
    } else {
      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        await _googleSignIn.signOut();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }

  Future<AuthClient?> getAuthenticatedClient() async {
    if (_useDesktopOAuth) {
      return _getDesktopAuthenticatedClient();
    }
    GoogleSignInAccount? account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) return null;
    return _googleSignIn.authenticatedClient();
  }

  bool get _useDesktopOAuth =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows);

  auth_io.ClientId? _desktopClientId() {
    final id = Env.googleDesktopClientId;
    if (id == null || id.isEmpty) return null;
    return auth_io.ClientId(id, Env.googleDesktopClientSecret ?? '');
  }

  Future<DriveAuthState?> _connectDesktopOAuth() async {
    final clientId = _desktopClientId();
    if (clientId == null) {
      throw StateError('Missing GOOGLE_DESKTOP_CLIENT_ID in .env');
    }

    final baseClient = http.Client();
    try {
      final credentials = await auth_io.obtainAccessCredentialsViaUserConsent(
        clientId,
        _scopes,
        baseClient,
        (url) async {
          final launched = await launchUrlString(url);
          if (!launched) {
            throw StateError('Could not open browser for Google sign-in.');
          }
        },
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_desktopCredsKey, _encodeCredentials(credentials));
      await prefs.setString(_emailKey, 'desktop-oauth');
      await prefs.setString(_nameKey, 'Desktop OAuth');
      return const DriveAuthState(
        isConnected: true,
        email: 'desktop-oauth',
        displayName: 'Desktop OAuth',
      );
    } finally {
      baseClient.close();
    }
  }

  Future<AuthClient?> _getDesktopAuthenticatedClient() async {
    final clientId = _desktopClientId();
    if (clientId == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_desktopCredsKey);
    if (raw == null || raw.isEmpty) return null;
    final creds = _decodeCredentials(raw);
    if (creds == null) return null;
    return auth_io.autoRefreshingClient(clientId, creds, http.Client());
  }

  String _encodeCredentials(AccessCredentials c) {
    final expiry = c.accessToken.expiry.toUtc().toIso8601String();
    final scopes = c.scopes.join(' ');
    return '${c.accessToken.type}|${c.accessToken.data}|$expiry|${c.refreshToken ?? ''}|$scopes';
  }

  AccessCredentials? _decodeCredentials(String raw) {
    final parts = raw.split('|');
    if (parts.length < 5) return null;
    final type = parts[0];
    final token = parts[1];
    final expiry = DateTime.tryParse(parts[2]) ?? DateTime.now().toUtc();
    final refreshToken = parts[3].isEmpty ? null : parts[3];
    final scopes = parts[4].isEmpty
        ? const <String>[]
        : parts[4].split(' ').where((s) => s.isNotEmpty).toList();
    return AccessCredentials(
      AccessToken(type, token, expiry),
      refreshToken,
      scopes,
    );
  }
}
