import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/router/app_router.dart';
import 'package:municipality/core/theme/app_theme.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/settings/presentation/locale_controller.dart';

class HealthPulseApp extends ConsumerWidget {
  const HealthPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Explain an automatic sign-out (server rejected the token).
    ref.listen(authControllerProvider, (_, next) {
      if (next.value case Unauthenticated(sessionExpired: true)) {
        final context = rootScaffoldMessengerKey.currentContext;
        if (context != null) showAppSnackBar(AppStrings.of(context).sessionExpired);
      }
    });

    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      onGenerateTitle: (context) => AppStrings.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      // Chosen language, or the device language until the user picks one.
      // Arabic gets RTL automatically, like the website.
      locale: ref.watch(localeControllerProvider),
      supportedLocales: AppStrings.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Theme(
        data: AppTheme.dark(Localizations.localeOf(context)),
        child: child!,
      ),
    );
  }
}
