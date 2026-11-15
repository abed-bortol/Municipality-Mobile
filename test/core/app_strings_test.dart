import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/widgets/brand_logo.dart';

Widget _localized(Locale locale, Widget child) => Localizations(
      locale: locale,
      delegates: const [
        GlobalWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: child,
    );

void main() {
  testWidgets('English strings match the website', (tester) async {
    late AppStrings s;
    await tester.pumpWidget(_localized(const Locale('en'), Builder(
      builder: (context) {
        s = AppStrings.of(context);
        return const SizedBox();
      },
    )));
    expect(s.appTitle, 'Tripoli HealthPulse');
    expect(s.isAr, isFalse);
  });

  testWidgets('Arabic locale uses Arabic strings and RTL', (tester) async {
    late AppStrings s;
    late TextDirection direction;
    await tester.pumpWidget(_localized(const Locale('ar'), Builder(
      builder: (context) {
        s = AppStrings.of(context);
        direction = Directionality.of(context);
        return const SizedBox();
      },
    )));
    expect(s.appTitle, 'نبض طرابلس الصحي');
    expect(direction, TextDirection.rtl);
  });

  testWidgets('BrandLogo renders at the requested size', (tester) async {
    await tester.pumpWidget(const Center(child: BrandLogo(size: 96)));
    expect(tester.getSize(find.byType(BrandLogo)), const Size(96, 96));
  });
}
