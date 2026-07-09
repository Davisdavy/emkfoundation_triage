import '../../../core/services/connectivity_service.dart';
import '../models/triage_record.dart';
import 'local_repository.dart';
import 'remote_repository.dart';

class TriageRepository {
  final LocalRepository localRepository;
  final RemoteRepository remoteRepository;
  final ConnectivityService connectivityService;

  TriageRepository({
    required this.localRepository,
    required this.remoteRepository,
    required this.connectivityService,
  });

  /// Submits a record using the offline-first flow:
  /// 1. Checks if online.
  /// 2. If online, attempts upload to RemoteRepository.
  ///    - If successful, saves locally with `isSynced = true`.
  ///    - If failed, saves locally with `isSynced = false`.
  /// 3. If offline, saves locally immediately with `isSynced = false`.
  /// Returns `true` if remote upload succeeded, `false` otherwise (saved locally).
  Future<bool> submitRecord(TriageRecord record) async {
    final online = await connectivityService.isOnline;

    if (online) {
      try {
        final success = await remoteRepository.uploadTriage(record);
        if (success) {
          final synced = record.copyWith(isSynced: true);
          await localRepository.saveRecord(synced);
          return true;
        }
      } catch (_) {
        // Fallback to local save if remote upload throws an exception
      }
    }

    final unsynced = record.copyWith(isSynced: false);
    await localRepository.saveRecord(unsynced);
    return false;
  }

  /// Retrieve all local records.
  List<TriageRecord> getAllRecords() {
    return localRepository.getAllRecords();
  }

  /// Retrieve all unsynced local records.
  List<TriageRecord> getUnsyncedRecords() {
    return localRepository.getUnsyncedRecords();
  }
}
