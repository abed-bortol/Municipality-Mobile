# Tripoli HealthPulse — Mobile (Flutter)

Mobile version of the Tripoli HealthPulse website
(`Desktop/HTML/Municipality`): Smart Public Health Surveillance & Reporting
for the Municipality of Greater Tripoli, Lebanon.

## First-time setup

1. Install Flutter (stable) and add it to `PATH`.
2. Run the setup script; it generates `android/` + `ios/`, applies the app
   name, the launcher icons and the native splash:

   ```powershell
   powershell -ExecutionPolicy Bypass -File tool\setup.ps1
   ```

3. Enable USB debugging on your Android phone, plug it in, then:

   ```powershell
   flutter run
   ```

## Branding

| Item | Source |
| --- | --- |
| App name | `Tripoli HealthPulse` / `نبض طرابلس الصحي` |
| Logo | `assets/branding/logo.svg` (copied from the website) |
| Colors | teal-600 `#0D9488` → cyan-500 `#06B6D4`, background slate-900 `#0F172A` |
| Fonts | Inter (English), Cairo (Arabic) via `google_fonts` |

The PNGs in `assets/branding/` (launcher icon, adaptive icon layers, splash
logos) are generated from the logo path. After changing them, re-run
`dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.

## Architecture

Feature-first, with `data / domain / presentation` layers inside each feature.

- **State:** Riverpod 3 with code generation (`@riverpod`)
- **Models and unions:** Freezed 3 + json_serializable
- **HTTP:** Dio
- **Navigation:** go_router, with redirects driven by auth state

```
lib/
  main.dart                    ProviderScope + SharedPreferences override
  app.dart                     MaterialApp.router, locales (en/ar + RTL), theme
  core/                        shared, feature-agnostic code
    config/env.dart            API URL (--dart-define=API_URL=...)
    network/                   dio provider, auth interceptor, ApiException
    storage/                   secure storage + shared prefs providers
    router/app_router.dart     routes + auth redirects
    l10n/app_strings.dart      bilingual strings (mirrors website t() keys)
    theme/                     colors + dark theme
    widgets/                   BrandLogo, PrimaryButton, ErrorBanner, messenger
  features/
    auth/
      domain/                  User, AuthState, RegisterRequest (freezed), AuthRepository
      data/                    remote (dio) + local (secure storage) sources, repository impl
      presentation/            AuthController (AsyncNotifier), AuthScreen, forms
    settings/                  language preference (LocaleController)
    splash/                    branded splash + AppStartupController
    home/                      placeholder home (next step: role dashboards)
```

Rules:
- **Dependencies point inward.** `presentation` uses `domain`, `data` implements `domain`, and widgets never touch Dio or storage directly.
- **Controllers stay off widgets.** They are `keepAlive` providers, and widgets only `watch` and `read` them.
- **Errors are typed.** Network failures are `ApiException`s, and the UI maps them to localized text.

After changing any `@riverpod` or `@freezed` code:

```powershell
dart run build_runner watch --delete-conflicting-outputs
```
