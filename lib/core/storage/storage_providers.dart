import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'storage_providers.g.dart';

/// Encrypted storage for secrets (JWT): Keychain on iOS, AES-GCM with
/// Keystore-wrapped keys on Android (the package default since v10).
@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) => const FlutterSecureStorage();

/// Plain preferences (language). Loaded in `main()` before the first frame
/// and injected with `sharedPreferencesProvider.overrideWithValue(...)`.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('Override sharedPreferencesProvider in main()');
