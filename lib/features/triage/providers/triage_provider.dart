import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/sync_service.dart';
import '../models/triage_record.dart';
import '../repositories/triage_repository.dart';

enum SubmissionOutcome {
  uploadedOnline,
  savedOffline,
}

class TriageProvider extends ChangeNotifier {
  final TriageRepository _repository;
  final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  List<TriageRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;

  TriageProvider({
    required TriageRepository repository,
    required SyncService syncService,
  })  : _repository = repository,
        _syncService = syncService {
    // Configure SyncService callbacks to auto-update UI when sync completes
    _syncService.onRecordsUpdated = _refreshFromRepository;
    _refreshFromRepository();
  }

  List<TriageRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all records from repository and sort them newest first.
  void _refreshFromRepository() {
    _records = _repository.getAllRecords();
    _records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  /// Refreshes the local record list manually.
  void refresh() {
    _refreshFromRepository();
  }

  /// Submits the triage form details. Coordinates with the Repository layer
  /// to attempt remote uploading or fallback to local offline storage.
  Future<SubmissionOutcome> submitTriage({
    required String patientName,
    required String conditionDescription,
    required int priority,
    required TriageStatus status,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final record = TriageRecord(
        id: _uuid.v4(),
        patientName: patientName.trim(),
        conditionDescription: conditionDescription.trim(),
        priority: priority,
        status: status,
        createdAt: DateTime.now(),
        isSynced: false,
      );

      final isSynced = await _repository.submitRecord(record);
      _refreshFromRepository();

      if (isSynced) {
        return SubmissionOutcome.uploadedOnline;
      } else {
        return SubmissionOutcome.savedOffline;
      }
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Triggers a manual sync.
  Future<void> triggerSync() async {
    await _syncService.syncPendingRecords();
    _refreshFromRepository();
  }
}
