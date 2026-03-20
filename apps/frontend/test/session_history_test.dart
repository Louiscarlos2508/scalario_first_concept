import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/auth/auth_state.dart';
import 'package:frontend/features/shared/reports/presentation/providers/report_providers.dart';
import 'package:frontend/features/shared/reports/presentation/screens/session_history_screen.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

final _session1 = {
  'id': 'sess-001',
  'userId': 'user-abcdefgh-1234',
  'deviceId': 'Terminal A',
  'openingBalance': 50000,
  'closingBalance': 175000,
  'theoreticalBalance': 175000,
  'variance': 0,
  'varianceExplanation': null,
  'openedAt': '2026-03-19T08:00:00.000Z',
  'closedAt': '2026-03-19T18:00:00.000Z',
  'status': 'CLOSED',
};

final _session2 = {
  'id': 'sess-002',
  'userId': 'user-zzzzzzzz-5678',
  'deviceId': 'Terminal B',
  'openingBalance': 30000,
  'closingBalance': 97000,
  'theoreticalBalance': 100000,
  'variance': -3000,
  'varianceExplanation': 'Erreur de rendu monnaie',
  'openedAt': '2026-03-18T09:00:00.000Z',
  'closedAt': '2026-03-18T17:30:00.000Z',
  'status': 'CLOSED',
};

final _sessionDetail = {
  'session': _session1,
  'totalsByMethod': {'CASH': 100000, 'MOBILE_MONEY': 25000},
  'totalSales': 125000,
  'grossSales': {'count': 12, 'amount': 125000},
  'returns': {'count': 0, 'amount': 0},
  'netSales': {'amount': 125000},
  'theoreticalCash': 150000,
  'openingBalance': 50000,
  'closingBalance': 175000,
  'theoreticalBalance': 175000,
  'variance': 0,
  'varianceExplanation': null,
};

// ── Builder helpers ───────────────────────────────────────────────────────────

Widget _buildScreen({
  required List<dynamic> sessions,
  Map<String, dynamic>? detail,
}) {
  return ProviderScope(
    overrides: [
      activeTenantProvider.overrideWith((ref) => 'tenant-1'),
      closedSessionsProvider.overrideWith(
        (ref) => Future.value(sessions),
      ),
      if (detail != null)
        sessionDetailProvider('sess-001').overrideWith(
          (ref) => Future.value(detail),
        ),
    ],
    child: const MaterialApp(home: SessionHistoryScreen()),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SessionHistoryScreen', () {
    testWidgets('shows empty state when no sessions', (tester) async {
      await tester.pumpWidget(_buildScreen(sessions: []));
      await tester.pump();

      expect(find.byKey(const Key('session_history_empty')), findsOneWidget);
      expect(find.text('Aucune session clôturée'), findsOneWidget);
    });

    testWidgets('renders session list when sessions present', (tester) async {
      await tester.pumpWidget(_buildScreen(sessions: [_session1, _session2]));
      await tester.pump();

      expect(find.byKey(const Key('session_history_list')), findsOneWidget);
      expect(find.byKey(const Key('session_card_sess-001')), findsOneWidget);
      expect(find.byKey(const Key('session_card_sess-002')), findsOneWidget);
      expect(find.text('Terminal A'), findsOneWidget);
      expect(find.text('Terminal B'), findsOneWidget);
    });

    testWidgets('negative variance card shows ecart label', (tester) async {
      await tester.pumpWidget(_buildScreen(sessions: [_session2]));
      await tester.pump();

      // variance -3000 should appear as formatted FCFA
      expect(find.textContaining('-3'), findsWidgets);
    });

    testWidgets('tap on session opens Z-report dialog', (tester) async {
      await tester.pumpWidget(
          _buildScreen(sessions: [_session1], detail: _sessionDetail));
      await tester.pump();

      await tester.tap(find.byKey(const Key('session_card_sess-001')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('z_report_dialog')), findsOneWidget);
      expect(find.text('Ventes par méthode de paiement'), findsOneWidget);
      expect(find.text('Réconciliation caisse'), findsOneWidget);
    });

    testWidgets('Z-report dialog shows payment methods', (tester) async {
      await tester.pumpWidget(
          _buildScreen(sessions: [_session1], detail: _sessionDetail));
      await tester.pump();

      await tester.tap(find.byKey(const Key('session_card_sess-001')));
      await tester.pumpAndSettle();

      expect(find.text('CASH'), findsOneWidget);
      expect(find.text('MOBILE_MONEY'), findsOneWidget);
    });

    testWidgets('Z-report close button dismisses dialog', (tester) async {
      await tester.pumpWidget(
          _buildScreen(sessions: [_session1], detail: _sessionDetail));
      await tester.pump();

      await tester.tap(find.byKey(const Key('session_card_sess-001')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('z_report_dialog')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('z_report_dialog')), findsNothing);
    });

    testWidgets('date filter button is present in AppBar', (tester) async {
      await tester.pumpWidget(_buildScreen(sessions: []));
      await tester.pump();

      expect(find.byKey(const Key('session_history_date_filter')),
          findsOneWidget);
    });

    testWidgets('filter applied shows correct empty label', (tester) async {
      await ProviderScope(
        overrides: [
          activeTenantProvider.overrideWith((ref) => 'tenant-1'),
          closedSessionsProvider.overrideWith((ref) => Future.value([])),
          closedSessionsDateRangeProvider.overrideWith((ref) => DateTimeRange(
                start: DateTime(2026, 3, 1),
                end: DateTime(2026, 3, 7),
              )),
        ],
        child: MaterialApp(home: Builder(builder: (context) {
          return const SessionHistoryScreen();
        })),
      ).run(tester);
      await tester.pump();

      expect(find.text('Aucune session sur cette période'), findsOneWidget);
    });
  });
}

// Helper to pump a ProviderScope directly
extension on ProviderScope {
  Future<void> run(WidgetTester tester) async {
    await tester.pumpWidget(this);
  }
}
