import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'features/triage/providers/triage_provider.dart';
import 'features/triage/repositories/triage_repository.dart';
import 'features/triage/screens/triage_screen.dart';
import 'features/triage/screens/splash_screen.dart';

class App extends StatelessWidget {
  final TriageRepository triageRepository;
  final ConnectivityService connectivityService;
  final SyncService syncService;

  const App({
    super.key,
    required this.triageRepository,
    required this.connectivityService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ConnectivityService>.value(value: connectivityService),
        Provider<TriageRepository>.value(value: triageRepository),
        Provider<SyncService>.value(value: syncService),
        ChangeNotifierProvider<TriageProvider>(
          create: (context) => TriageProvider(
            repository: triageRepository,
            syncService: syncService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Medic Triage',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
