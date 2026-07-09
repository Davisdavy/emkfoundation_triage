import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'features/triage/models/triage_record.dart';
import 'features/triage/repositories/local_repository.dart';
import 'features/triage/repositories/remote_repository.dart';
import 'features/triage/repositories/triage_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage
  await Hive.initFlutter();

  // Register the manual type adapter
  Hive.registerAdapter(TriageRecordAdapter());

  // Open the box to persist triage records
  final box = await Hive.openBox<TriageRecord>('triage_records');

  // Instantiate services and repositories
  final connectivityService = ConnectivityService();
  final localRepository = LocalRepository(box);
  final remoteRepository = RemoteRepository();
  
  final triageRepository = TriageRepository(
    localRepository: localRepository,
    remoteRepository: remoteRepository,
    connectivityService: connectivityService,
  );

  final syncService = SyncService(
    repository: triageRepository,
    connectivityService: connectivityService,
  );

  // Initialize background sync monitoring
  syncService.init();

  runApp(
    App(
      triageRepository: triageRepository,
      connectivityService: connectivityService,
      syncService: syncService,
    ),
  );
}
