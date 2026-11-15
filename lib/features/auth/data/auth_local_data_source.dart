import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:municipality/core/storage/storage_providers.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_local_data_source.g.dart';

@Riverpod(keepAlive: true)
AuthLocalDataSource authLocalDataSource(Ref ref) =>
    AuthLocalDataSource(ref.watch(secureStorageProvider));

/// Persists the session on the device (same keys as the website's
/// `utils/authStorage.ts`, but in encrypted storage).
class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  static const _tokenKey = 'tripoli_healthpulse_token';
  static const _userKey = 'tripoli_healthpulse_user';

  final FlutterSecureStorage _storage;

  // Read on every request by the auth interceptor, so keep it in memory.
  String? _token;
  bool _tokenLoaded = false;

  Future<String?> readToken() async {
    if (!_tokenLoaded) {
      _token = await _storage.read(key: _tokenKey);
      _tokenLoaded = true;
    }
    return _token;
  }

  Future<User?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    try {
      return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null; // Corrupt or from an older format: treat as signed out.
    }
  }

  Future<void> saveSession({required String token, required User user}) async {
    _token = token;
    _tokenLoaded = true;
    await _storage.write(key: _tokenKey, value: token);
    await saveUser(user);
  }

  Future<void> saveUser(User user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  Future<void> clear() async {
    _token = null;
    _tokenLoaded = true;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
