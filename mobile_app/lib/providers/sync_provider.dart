import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { idle, syncing, success, error }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

final lastSyncTimeProvider = StateProvider<DateTime?>((ref) => null);
