import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_triage/app.dart';
import 'package:rapid_triage/core/services/sync_service.dart';
import 'package:rapid_triage/features/triage/repositories/triage_repository.dart';
import 'triage_test.dart';

void main() {
  testWidgets('Triage screen renders form elements', (WidgetTester tester) async {
    final connectivity = FakeConnectivityService()..setOnline(true);
    final local = FakeLocalRepository();
    final remote = FakeRemoteRepository();
    final repo = TriageRepository(
      localRepository: local,
      remoteRepository: remote,
      connectivityService: connectivity,
    );
    final syncService = SyncService(
      repository: repo,
      connectivityService: connectivity,
    );

    await tester.pumpWidget(
      App(
        triageRepository: repo,
        connectivityService: connectivity,
        syncService: syncService,
      ),
    );

    expect(find.text('Patient Intake Form'), findsOneWidget);
    expect(find.text('SUBMIT TRIAGE RECORD'), findsOneWidget);
  });
}
