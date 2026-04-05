import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import 'presentation/screens/app_router.dart';
import 'presentation/theme/app_theme.dart';
import 'providers/core_providers.dart';
import 'providers/theme_provider.dart';
import 'services/sync_service.dart';

void main() {
  runApp(const ProviderScope(child: FinanceApp()));
}

class FinanceApp extends ConsumerStatefulWidget {
  final bool enableSync;

  const FinanceApp({super.key, this.enableSync = true});

  @override
  ConsumerState<FinanceApp> createState() => _FinanceAppState();
}

class _FinanceAppState extends ConsumerState<FinanceApp> {
  SyncService? _syncService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    if (!widget.enableSync) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncService = SyncService(
        apiClient: ref.read(apiClientProvider),
        database: ref.read(databaseProvider),
        connectivity: Connectivity(),
      );

      _syncService!.triggerSync(ref);

      _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
        if (result.contains(ConnectivityResult.mobile) ||
            result.contains(ConnectivityResult.wifi) ||
            result.contains(ConnectivityResult.ethernet)) {
          _syncService?.triggerSync(ref);
        }
      });
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Zovryn Finance',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
