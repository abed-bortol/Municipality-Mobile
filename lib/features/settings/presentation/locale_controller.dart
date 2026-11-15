import 'dart:ui';

import 'package:municipality/features/settings/data/settings_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_controller.g.dart';

/// The user's chosen language, or `null` to follow the device language.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  Locale? build() {
    final code = ref.watch(settingsRepositoryProvider).languageCode;
    return code == null ? null : Locale(code);
  }

  Future<void> setLanguage(String code) async {
    state = Locale(code);
    await ref.read(settingsRepositoryProvider).setLanguageCode(code);
  }
}
