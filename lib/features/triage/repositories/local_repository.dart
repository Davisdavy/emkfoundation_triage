import 'package:hive/hive.dart';
import '../models/triage_record.dart';

class LocalRepository {
  final Box<TriageRecord> _box;

  LocalRepository(this._box);

  /// Save or update a triage record locally.
  Future<void> saveRecord(TriageRecord record) async {
    await _box.put(record.id, record);
  }

  /// Retrieve all records stored locally.
  List<TriageRecord> getAllRecords() {
    return _box.values.toList();
  }

  /// Retrieve only local records that haven't been synchronized yet.
  List<TriageRecord> getUnsyncedRecords() {
    return _box.values.where((record) => !record.isSynced).toList();
  }

  /// Update the sync status of a record by ID.
  Future<void> updateSyncStatus(String id, bool isSynced) async {
    final record = _box.get(id);
    if (record != null) {
      final updated = record.copyWith(isSynced: isSynced);
      await _box.put(id, updated);
    }
  }

  /// Delete a local record by ID (if needed).
  Future<void> deleteRecord(String id) async {
    await _box.delete(id);
  }
}
