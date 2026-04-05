import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/model/goal_model.dart';
import '../data/remote/api_client.dart';
import 'core_providers.dart';

class GoalNotifier extends StateNotifier<AsyncValue<List<Goal>>> {
  final ApiClient apiClient;
  final AppDatabase database;

  GoalNotifier(this.apiClient, this.database)
    : super(const AsyncValue.loading()) {
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await database.getAllGoals();
      state = AsyncValue.data(
        goals.map((g) {
          return Goal(
            id: g.id,
            name: g.name,
            targetAmount: g.targetAmount,
            month: g.month,
            isSynced: g.isSynced,
            isDeleted: g.isDeleted,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(g.updatedAt),
          );
        }).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(Goal goal) async {
    try {
      await database.insertOrUpdateGoal(
        GoalTableData(
          id: goal.id,
          name: goal.name,
          targetAmount: goal.targetAmount,
          month: goal.month,
          isSynced: false,
          isDeleted: false,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await _loadGoals();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteGoal(String id) async {
    try {
      await database.softDeleteGoal(id);
      await _loadGoals();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await database.insertOrUpdateGoal(
        GoalTableData(
          id: goal.id,
          name: goal.name,
          targetAmount: goal.targetAmount,
          month: goal.month,
          isSynced: false,
          isDeleted: false,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await _loadGoals();
    } catch (e) {
      rethrow;
    }
  }
}

final goalProvider =
    StateNotifierProvider<GoalNotifier, AsyncValue<List<Goal>>>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      final database = ref.watch(databaseProvider);
      return GoalNotifier(apiClient, database);
    });
