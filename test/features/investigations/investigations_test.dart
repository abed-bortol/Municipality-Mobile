import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/investigations/data/investigations_repository.dart';
import 'package:municipality/features/investigations/domain/investigation.dart';
import 'package:municipality/features/investigations/presentation/investigations_providers.dart';
import 'package:municipality/features/investigations/presentation/screens/investigation_form_screen.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/presentation/reports_providers.dart';
import 'package:municipality/l10n/l10n.dart';

class FakeInvestigationsRepository implements InvestigationsRepository {
  FakeInvestigationsRepository([this.stored = const []]);

  List<Investigation> stored;
  final calls = <String>[];
  final drafts = <InvestigationDraft>[];

  @override
  Future<List<Investigation>> getInvestigations() async => stored;

  @override
  Future<Investigation> save(String reportId, InvestigationDraft draft) async {
    calls.add('save:$reportId');
    drafts.add(draft);
    return Investigation(id: 'i-new', reportId: reportId);
  }

  @override
  Future<Investigation> update(String id, InvestigationDraft draft) async {
    calls.add('update:$id');
    drafts.add(draft);
    return Investigation(id: id);
  }

  @override
  Future<Report> finalize(String reportId, InvestigationDraft draft) async {
    calls.add('finalize:$reportId');
    drafts.add(draft);
    return Report(id: reportId, status: ReportStatus.resolved);
  }
}

const _verified = Report(
  id: 'r1',
  reportNumber: 'TRP-1',
  title: 'Brown tap water',
  status: ReportStatus.verified,
);

void main() {
  group('Investigation JSON', () {
    test('fromJson reads the populated report and officer', () {
      final inv = Investigation.fromJson({
        '_id': 'i1',
        'investigationCode': 'INV-2026-0001',
        'reportId': {
          '_id': 'r1',
          'reportNumber': 'TRP-1',
          'title': 'Brown tap water',
          'status': 'IN_INVESTIGATION',
        },
        'officer': {'userId': 'o1', 'name': 'Dr. Lina', 'badgeNumber': 'HO-7'},
        'result': 'Not Confirmed',
        'status': 'PENDING',
      });
      expect(inv.reportId, 'r1');
      expect(inv.reportNumber, 'TRP-1');
      expect(inv.reportTitle, 'Brown tap water');
      expect(inv.reportStatus, ReportStatus.inInvestigation);
      expect(inv.officerName, 'Dr. Lina');
      expect(inv.officerBadge, 'HO-7');
      expect(inv.result, InvestigationResult.notConfirmed);
      expect(inv.status, InvestigationStatus.pending);
    });

    test('fromJson with a plain report id and unknown values', () {
      final inv = Investigation.fromJson({
        '_id': 'i2',
        'reportId': 'r9',
        'reportNumber': 'TRP-9',
        'result': 'Maybe',
        'status': 'ARCHIVED',
      });
      expect(inv.reportId, 'r9');
      expect(inv.reportStatus, isNull);
      expect(inv.result, InvestigationResult.inconclusive);
      expect(inv.status, InvestigationStatus.inProgress);
    });

    test('draft uses the server values and skips a null status', () {
      const draft = InvestigationDraft(
        findings: 'f',
        actionsTaken: 'a',
        result: InvestigationResult.notConfirmed,
      );
      expect(draft.toJson(), {
        'findings': 'f',
        'actionsTaken': 'a',
        'recommendations': '',
        'result': 'Not Confirmed',
        'samplesCollected': '',
        'notes': '',
      });
      expect(
        draft.copyWith(status: InvestigationStatus.inProgress).toJson()['status'],
        'IN_PROGRESS',
      );
    });
  });

  group('InvestigationActions', () {
    late FakeInvestigationsRepository repo;
    late ProviderContainer container;

    setUp(() {
      repo = FakeInvestigationsRepository();
      container = ProviderContainer(overrides: [
        investigationsRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(container.dispose);
    });

    InvestigationActions actions() =>
        container.read(investigationActionsProvider.notifier);

    test('a draft never completes the investigation', () async {
      await actions().save(
        _verified,
        const InvestigationDraft(
          findings: 'f',
          actionsTaken: 'a',
          status: InvestigationStatus.completed,
        ),
      );
      expect(repo.calls, ['save:r1']);
      expect(repo.drafts.single.status, InvestigationStatus.inProgress);
    });

    test('a completed record is edited in place', () async {
      await actions().save(
        _verified.copyWith(status: ReportStatus.resolved),
        const InvestigationDraft(findings: 'f', actionsTaken: 'a'),
        existing: const Investigation(
            id: 'i1', status: InvestigationStatus.completed),
      );
      expect(repo.calls, ['update:i1']);
    });

    test('finalizing a verified report opens the investigation first',
        () async {
      final report = await actions().finalize(
        _verified,
        const InvestigationDraft(
          findings: 'f',
          actionsTaken: 'a',
          result: InvestigationResult.inconclusive,
        ),
      );
      expect(repo.calls, ['save:r1', 'finalize:r1']);
      final closing = repo.drafts.last;
      // Website: inconclusive becomes resolved, empty texts get defaults.
      expect(closing.result, InvestigationResult.resolved);
      expect(closing.recommendations, isNotEmpty);
      expect(closing.notes, isNotEmpty);
      expect(closing.status, isNull);
      expect(report.status, ReportStatus.resolved);
    });

    test('finalizing a report already in investigation', () async {
      await actions().finalize(
        _verified.copyWith(status: ReportStatus.inInvestigation),
        const InvestigationDraft(findings: 'f', actionsTaken: 'a'),
      );
      expect(repo.calls, ['finalize:r1']);
    });
  });

  test('the investigation form is staff only', () {
    const path = '/reports/r1/investigation';
    expect(AppRoutes.reportInvestigation('r1'), path);
    expect(AppRoutes.canAccess(path, UserRole.citizen), isFalse);
    expect(AppRoutes.canAccess(path, UserRole.healthOfficer), isTrue);
    expect(AppRoutes.canAccess('/reports/r1', UserRole.citizen), isTrue);
  });

  testWidgets('form requires findings and actions, then finalizes',
      (tester) async {
    final repo = FakeInvestigationsRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        investigationsRepositoryProvider.overrideWithValue(repo),
        reportDetailsProvider('r1').overrideWith((_) async => _verified),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const InvestigationFormScreen(reportId: 'r1'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Related to Report: #TRP-1'), findsOneWidget);

    final finalize = find.text('Finalize Inspection & Resolve (Final)');
    await tester.ensureVisible(finalize);
    await tester.tap(finalize);
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    expect(find.text('Please specify field findings and observations.'),
        findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Field Findings *'), 'Brown water');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Containment & Actions Taken *'),
        'Valve shut');
    await tester.ensureVisible(finalize);
    await tester.tap(finalize);
    await tester.pumpAndSettle();
    // Confirmation dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Finalize Inspection'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['save:r1', 'finalize:r1']);
    expect(repo.drafts.last.findings, 'Brown water');
    expect(
        find.text(
            'Field inspection finalized and report #TRP-1 marked RESOLVED!'),
        findsOneWidget);
  });
}
