import 'dart:async';
import '../../features/triage/repositories/triage_repository.dart';
import 'connectivity_service.dart';

class SyncService {
  final TriageRepository _repository;
  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _subscription;
  bool _isSyncing = false;

  /// Callback when records are updated/synchronized, allowing providers to refresh UI state.
  void Function()? onRecordsUpdated;

  /// Callback to notify UI with the number of successfully synced records.
  void Function(int count)? onSyncCompleted;

  SyncService({
    required TriageRepository repository,
    required ConnectivityService connectivityService,
  })  : _repository = repository,
        _connectivityService = connectivityService;

  /// Initialize the synchronization monitoring.
  void init() {
    _subscription = _connectivityService.isOnlineStream.listen((isOnline) {
      if (isOnline) {
        syncPendingRecords();
      }
    });
  }

  /// Clean up connectivity subscription.
  void dispose() {
    _subscription?.cancel();
  }

  /// Sync all pending (unsynced) records one-by-one.
  Future<void> syncPendingRecords() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final unsynced = _repository.getUnsyncedRecords();
      if (unsynced.isEmpty) return;

      int syncedCount = 0;
      for (final record in unsynced) {
        // Re-verify connectivity status before each record upload
        final online = await _connectivityService.isOnline;
        if (!online) break;

        try {
          final success = await _repository.remoteRepository.uploadTriage(record);
          if (success) {
            await _repository.localRepository.updateSyncStatus(record.id, true);
            syncedCount++;
            onRecordsUpdated?.call();
          }
        } catch (_) {
          // If a single record fails, continue to try syncing other records
        }
      }

      if (syncedCount > 0 && onSyncCompleted != null) {
        onSyncCompleted!(syncedCount);
      }
    } finally {
      _isSyncing = false;
    }
  }
}
