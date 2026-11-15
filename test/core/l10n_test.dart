import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/widgets/brand_logo.dart';
import 'package:municipality/l10n/l10n.dart';

Future<BuildContext> _pumpLocale(WidgetTester tester, Locale locale) async {
  late BuildContext captured;
  await tester.pumpWidget(Localizations(
    locale: locale,
    delegates: AppLocalizations.localizationsDelegates,
    child: Builder(builder: (context) {
      captured = context;
      return const SizedBox();
    }),
  ));
  return captured;
}

void main() {
  testWidgets('English strings match the website', (tester) async {
    final context = await _pumpLocale(tester, const Locale('en'));
    expect(context.l10n.appTitle, 'Tripoli HealthPulse');
    expect(context.isArabic, isFalse);
  });

  testWidgets('Arabic locale uses Arabic strings and RTL', (tester) async {
    final context = await _pumpLocale(tester, const Locale('ar'));
    expect(context.l10n.appTitle, 'نبض طرابلس الصحي');
    expect(context.isArabic, isTrue);
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('server values are translated, unknown ones pass through',
      (tester) async {
    final l10n = (await _pumpLocale(tester, const Locale('ar'))).l10n;
    expect(l10n.statusLabel('IN_INVESTIGATION'), 'قيد التحقيق الميداني');
    expect(l10n.districtName('Al-Mina'), 'الميناء');
    expect(l10n.roleLabel('HEALTH_OFFICER'), 'مراقب صحي');
    expect(l10n.categoryName('Other'), 'أخرى');
    expect(l10n.riskLabel('UNKNOWN'), 'UNKNOWN');
  });

  testWidgets('BrandLogo renders at the requested size', (tester) async {
    await tester.pumpWidget(const Center(child: BrandLogo(size: 96)));
    expect(tester.getSize(find.byType(BrandLogo)), const Size(96, 96));
  });
}
