import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/app_database.dart';
import '../data/remote/api_client.dart';

// Singleton providers
final apiClientProvider = Provider((ref) => ApiClient());

final databaseProvider = Provider((ref) => AppDatabase());

final sharedPreferencesProvider = FutureProvider((ref) async {
  return await SharedPreferences.getInstance();
});
