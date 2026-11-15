import 'package:municipality/core/storage/storage_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_repository.g.dart';

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) =>
    SettingsRepository(ref.watch(sharedPreferencesProvider));

class SettingsRepository {
  SettingsRepository(this._prefs);

  // Same key as the website's LanguageContext.
  static const _languageKey = 'tripoli_healthpulse_lang';

  final SharedPreferences _prefs;

  String? get languageCode => _prefs.getString(_languageKey);

  Future<void> setLanguageCode(String code) =>
      _prefs.setString(_languageKey, code);
}
