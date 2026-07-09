import 'dart:math';
import '../models/triage_record.dart';

class RemoteRepository {
  final Random _random;

  RemoteRepository({Random? random}) : _random = random ?? Random();

  /// Simulates uploading a triage record with a 2-second delay and 30% random failure rate.
  Future<bool> uploadTriage(TriageRecord record) async {
    await Future.delayed(const Duration(seconds: 2));
    
    final isSuccess = _random.nextDouble() >= 0.3;
    return isSuccess;
  }
}
