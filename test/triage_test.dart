import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_triage/core/services/connectivity_service.dart';
import 'package:rapid_triage/core/services/sync_service.dart';
import 'package:rapid_triage/features/triage/models/triage_record.dart';
import 'package:rapid_triage/features/triage/providers/triage_provider.dart';
import 'package:rapid_triage/features/triage/repositories/local_repository.dart';
import 'package:rapid_triage/features/triage/repositories/remote_repository.dart';
import 'package:rapid_triage/features/triage/repositories/triage_repository.dart';

class FakeConnectivityService implements ConnectivityService {
  bool onlineStatus = true;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  void setOnline(bool status) {
    onlineStatus = status;
    _controller.add(status);
  }

  @override
  Future<bool> get isOnline async => onlineStatus;

  @override
  Stream<bool> get isOnlineStream => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

class FakeLocalRepository implements LocalRepository {
  final Map<String, TriageRecord> records = {};

  @override
  Future<void> saveRecord(TriageRecord record) async {
    records[record.id] = record;
  }

  @override
  List<TriageRecord> getAllRecords() {
    return records.values.toList();
  }

  @override
  List<TriageRecord> getUnsyncedRecords() {
    return records.values.where((r) => !r.isSynced).toList();
  }

  @override
  Future<void> updateSyncStatus(String id, bool isSynced) async {
    final record = records[id];
    if (record != null) {
      records[id] = record.copyWith(isSynced: isSynced);
    }
  }

  @override
  Future<void> deleteRecord(String id) async {
    records.remove(id);
  }
  
  @override
  dynamic get _box => null;
}

class FakeRemoteRepository implements RemoteRepository {
  bool shouldSucceed = true;
  int uploadCount = 0;
  List<TriageRecord> uploadedRecords = [];

  @override
  Future<bool> uploadTriage(TriageRecord record) async {
    uploadCount++;
    if (shouldSucceed) {
      uploadedRecords.add(record);
      return true;
    }
    return false;
  }
  
  @override
  dynamic get _random => null;
}

void main() {
  group('Triage Offline-First Tests', () {
    test('Offline submission saves locally and marks record as unsynced', () async {
      final connectivity = FakeConnectivityService()..setOnline(false);
      final local = FakeLocalRepository();
      final remote = FakeRemoteRepository();
      final repo = TriageRepository(
        localRepository: local,
        remoteRepository: remote,
        connectivityService: connectivity,
      );

      final record = TriageRecord(
        id: 'rec_offline',
        patientName: 'Offline Patient',
        conditionDescription: 'Fractured wrist',
        priority: 4,
        status: TriageStatus.pending,
        createdAt: DateTime.now(),
      );

      final wasUploaded = await repo.submitRecord(record);

      expect(wasUploaded, isFalse);
      expect(local.records.length, 1);
      expect(local.records['rec_offline']!.isSynced, isFalse);
      expect(remote.uploadCount, 0);
    });

    test('Online submission uploads successfully and marks record as synced', () async {
      final connectivity = FakeConnectivityService()..setOnline(true);
      final local = FakeLocalRepository();
      final remote = FakeRemoteRepository()..shouldSucceed = true;
      final repo = TriageRepository(
        localRepository: local,
        remoteRepository: remote,
        connectivityService: connectivity,
      );

      final record = TriageRecord(
        id: 'rec_online',
        patientName: 'Online Patient',
        conditionDescription: 'Severe chest pain',
        priority: 1,
        status: TriageStatus.inTransit,
        createdAt: DateTime.now(),
      );

      final wasUploaded = await repo.submitRecord(record);

      expect(wasUploaded, isTrue);
      expect(local.records.length, 1);
      expect(local.records['rec_online']!.isSynced, isTrue);
      expect(remote.uploadCount, 1);
    });

    test('Failed upload stores record locally as unsynced', () async {
      final connectivity = FakeConnectivityService()..setOnline(true);
      final local = FakeLocalRepository();
      final remote = FakeRemoteRepository()..shouldSucceed = false;
      final repo = TriageRepository(
        localRepository: local,
        remoteRepository: remote,
        connectivityService: connectivity,
      );

      final record = TriageRecord(
        id: 'rec_failed_upload',
        patientName: 'Failed Upload Patient',
        conditionDescription: 'High fever',
        priority: 3,
        status: TriageStatus.pending,
        createdAt: DateTime.now(),
      );

      final wasUploaded = await repo.submitRecord(record);

      expect(wasUploaded, isFalse);
      expect(local.records.length, 1);
      expect(local.records['rec_failed_upload']!.isSynced, isFalse);
      expect(remote.uploadCount, 1);
    });

    test('Sync service uploads pending records and marks them as synced', () async {
      final connectivity = FakeConnectivityService()..setOnline(false);
      final local = FakeLocalRepository();
      final remote = FakeRemoteRepository()..shouldSucceed = true;
      final repo = TriageRepository(
        localRepository: local,
        remoteRepository: remote,
        connectivityService: connectivity,
      );

      final record1 = TriageRecord(
        id: 'rec_sync_1',
        patientName: 'Sync Patient 1',
        conditionDescription: 'Allergic reaction',
        priority: 2,
        status: TriageStatus.pending,
        createdAt: DateTime.now(),
        isSynced: false,
      );
      final record2 = TriageRecord(
        id: 'rec_sync_2',
        patientName: 'Sync Patient 2',
        conditionDescription: 'Superficial cuts',
        priority: 5,
        status: TriageStatus.inTransit,
        createdAt: DateTime.now(),
        isSynced: false,
      );

      await local.saveRecord(record1);
      await local.saveRecord(record2);

      final syncService = SyncService(
        repository: repo,
        connectivityService: connectivity,
      );

      int notifiedCount = 0;
      syncService.onSyncCompleted = (count) {
        notifiedCount = count;
      };

      // Restore connectivity
      connectivity.setOnline(true);

      // Perform background sync
      await syncService.syncPendingRecords();

      expect(remote.uploadCount, 2);
      expect(local.records['rec_sync_1']!.isSynced, isTrue);
      expect(local.records['rec_sync_2']!.isSynced, isTrue);
      expect(notifiedCount, 2);
    });

    test('TriageProvider state and loading updates correctly', () async {
      final connectivity = FakeConnectivityService()..setOnline(true);
      final local = FakeLocalRepository();
      final remote = FakeRemoteRepository()..shouldSucceed = true;
      final repo = TriageRepository(
        localRepository: local,
        remoteRepository: remote,
        connectivityService: connectivity,
      );
      final syncService = SyncService(
        repository: repo,
        connectivityService: connectivity,
      );

      final provider = TriageProvider(
        repository: repo,
        syncService: syncService,
      );

      expect(provider.isLoading, isFalse);
      expect(provider.records.isEmpty, isTrue);

      final submitFuture = provider.submitTriage(
        patientName: 'Provider Patient',
        conditionDescription: 'Asthma attack',
        priority: 1,
        status: TriageStatus.inTransit,
      );

      expect(provider.isLoading, isTrue);

      final outcome = await submitFuture;

      expect(provider.isLoading, isFalse);
      expect(outcome, SubmissionOutcome.uploadedOnline);
      expect(provider.records.length, 1);
      expect(provider.records.first.patientName, 'Provider Patient');
    });
  });
}
