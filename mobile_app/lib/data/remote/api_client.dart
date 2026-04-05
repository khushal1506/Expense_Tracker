import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../model/api_models.dart';
import '../model/goal_model.dart';
import '../model/transaction_model.dart';

class ApiClient {
  late Dio _dio;
  String? _cachedClientId;

  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://13.63.211.128/api/',
  );
  static const String _clientIdPrefsKey = 'client_id';

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final clientId = await _getOrCreateClientId();
          options.headers['X-Client-Id'] = clientId;
          options.headers['X-User-Email'] = 'client.$clientId@zovryn.dev';
          handler.next(options);
        },
      ),
    );
  }

  Future<String> _getOrCreateClientId() async {
    if (_cachedClientId != null && _cachedClientId!.isNotEmpty) {
      return _cachedClientId!;
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_clientIdPrefsKey);
    if (existing != null && existing.isNotEmpty) {
      _cachedClientId = existing;
      return existing;
    }

    final newClientId = const Uuid().v4();
    await prefs.setString(_clientIdPrefsKey, newClientId);
    _cachedClientId = newClientId;
    return newClientId;
  }

  // Transaction endpoints
  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await _dio.get('/transactions');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data.map((json) => Transaction.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Transaction> createTransaction(Transaction transaction) async {
    try {
      final response = await _dio.post(
        '/transactions',
        data: transaction.toJson(),
      );
      return Transaction.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Transaction> updateTransaction(
    String id,
    Transaction transaction,
  ) async {
    try {
      final response = await _dio.put(
        '/transactions/$id',
        data: transaction.toJson(),
      );
      return Transaction.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await _dio.delete('/transactions/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Goal endpoints
  Future<List<Goal>> getGoals() async {
    try {
      final response = await _dio.get('/goals');
      final List<dynamic> data = response.data['data'] as List<dynamic>;
      return data.map((json) => Goal.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Goal> createGoal(Goal goal) async {
    try {
      final response = await _dio.post('/goals', data: goal.toJson());
      return Goal.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Goal> updateGoal(String id, Goal goal) async {
    try {
      final response = await _dio.put('/goals/$id', data: goal.toJson());
      return Goal.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await _dio.delete('/goals/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Sync endpoints
  Future<SyncPushResponse> syncPush({
    required List<Transaction> transactions,
    required List<Goal> goals,
  }) async {
    try {
      final response = await _dio.post(
        '/sync/push',
        data: {
          'transactions': transactions.map((t) => t.toJson()).toList(),
          'goals': goals.map((g) => g.toJson()).toList(),
        },
      );
      return SyncPushResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }

  Future<SyncPullResponse> syncPull(DateTime since) async {
    try {
      final response = await _dio.get(
        '/sync/pull',
        queryParameters: {'since': since.toUtc().toIso8601String()},
      );
      return SyncPullResponse.fromJson(response.data['data']);
    } catch (e) {
      rethrow;
    }
  }
}
