import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database/app_database.dart';
import '../data/model/transaction_model.dart';
import '../data/model/goal_model.dart';
import '../data/remote/api_client.dart';
import '../providers/sync_provider.dart';

class SyncService {
  final ApiClient apiClient;
  final AppDatabase database;
  final Connectivity connectivity;

  SyncService({
    required this.apiClient,
    required this.database,
    required this.connectivity,
  });

  Future<void> triggerSync(WidgetRef ref) async {
    try {
      // Check connectivity
      final result = await connectivity.checkConnectivity();
      if (result.isEmpty || result.contains(ConnectivityResult.none)) {
        // No connectivity, fail silently
        ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
        return;
      }

      ref.read(syncStatusProvider.notifier).state = SyncStatus.syncing;

      // Step 1: PUSH - send unsynced records to server
      await _pushToServer();

      // Step 2: PULL - fetch changed records from server
      await _pullFromServer();

      ref.read(syncStatusProvider.notifier).state = SyncStatus.success;
      ref.read(lastSyncTimeProvider.notifier).state = DateTime.now();

      // Reset status after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
    } catch (e) {
      ref.read(syncStatusProvider.notifier).state = SyncStatus.error;
      debugPrint('Sync error: $e');

      // Reset status after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      ref.read(syncStatusProvider.notifier).state = SyncStatus.idle;
    }
  }

  Future<void> _pushToServer() async {
    try {
      // Load unsynced transactions and goals
      final unsyncedTransactions = await database.getUnsyncedTransactions();
      final unsyncedGoals = await database.getUnsyncedGoals();

      if (unsyncedTransactions.isEmpty && unsyncedGoals.isEmpty) {
        return; // Nothing to push
      }

      // Convert to models
      final transactionModels = unsyncedTransactions.map((t) {
        return Transaction(
          id: t.id,
          amount: t.amount,
          type: t.type == 'INCOME'
              ? TransactionType.income
              : TransactionType.expense,
          category: t.category,
          date: t.date,
          notes: t.notes,
          isSynced: t.isSynced,
          isDeleted: t.isDeleted,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(t.updatedAt),
        );
      }).toList();

      final goalModels = unsyncedGoals.map((g) {
        return Goal(
          id: g.id,
          name: g.name,
          targetAmount: g.targetAmount,
          month: g.month,
          isSynced: g.isSynced,
          isDeleted: g.isDeleted,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(g.updatedAt),
        );
      }).toList();

      // POST to /api/sync/push
      final response = await apiClient.syncPush(
        transactions: transactionModels,
        goals: goalModels,
      );

      // Mark all as synced except skipped ones
      final allIds = [
        ...unsyncedTransactions.map((t) => t.id),
        ...unsyncedGoals.map((g) => g.id),
      ];
      final successIds = allIds
          .where((id) => !response.skippedIds.contains(id))
          .toList();

      // Separate transaction and goal IDs
      final successTransactionIds = successIds.where((id) {
        return unsyncedTransactions.any((t) => t.id == id);
      }).toList();

      final successGoalIds = successIds.where((id) {
        return unsyncedGoals.any((g) => g.id == id);
      }).toList();

      if (successTransactionIds.isNotEmpty) {
        await database.markTransactionsAsSynced(successTransactionIds);
      }
      if (successGoalIds.isNotEmpty) {
        await database.markGoalsAsSynced(successGoalIds);
      }
    } catch (e) {
      debugPrint('Push error: $e');
      rethrow;
    }
  }

  Future<void> _pullFromServer() async {
    try {
      // Get last sync timestamp
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString('last_sync_timestamp');
      final lastSync = lastSyncStr != null
          ? DateTime.parse(lastSyncStr)
          : DateTime.fromMillisecondsSinceEpoch(0);

      // GET /api/sync/pull?since={timestamp}
      final response = await apiClient.syncPull(lastSync);

      // Process transactions
      for (final transactionJson in response.transactions) {
        final transaction = Transaction.fromJson(transactionJson);
        // Check if exists locally
        final existing = await database.getTransactionById(transaction.id);

        if (existing == null) {
          // New transaction - insert
          await database.insertOrUpdateTransaction(
            TransactionTableData(
              id: transaction.id,
              amount: transaction.amount,
              type: transaction.type == TransactionType.income
                  ? 'INCOME'
                  : 'EXPENSE',
              category: transaction.category,
              date: transaction.date,
              notes: transaction.notes,
              isSynced: true,
              isDeleted: transaction.isDeleted,
              updatedAt: transaction.updatedAt.millisecondsSinceEpoch,
            ),
          );
        } else {
          // Exists - check if server is newer
          if (transaction.updatedAt.isAfter(
            DateTime.fromMillisecondsSinceEpoch(existing.updatedAt),
          )) {
            // Update
            await database.insertOrUpdateTransaction(
              TransactionTableData(
                id: transaction.id,
                amount: transaction.amount,
                type: transaction.type == TransactionType.income
                    ? 'INCOME'
                    : 'EXPENSE',
                category: transaction.category,
                date: transaction.date,
                notes: transaction.notes,
                isSynced: true,
                isDeleted: transaction.isDeleted,
                updatedAt: transaction.updatedAt.millisecondsSinceEpoch,
              ),
            );
          }
        }
      }

      // Process goals
      for (final goalJson in response.goals) {
        final goal = Goal.fromJson(goalJson);
        // Check if exists locally
        final existing = await database.getGoalById(goal.id);

        if (existing == null) {
          // New goal - insert
          await database.insertOrUpdateGoal(
            GoalTableData(
              id: goal.id,
              name: goal.name,
              targetAmount: goal.targetAmount,
              month: goal.month,
              isSynced: true,
              isDeleted: goal.isDeleted,
              updatedAt: goal.updatedAt.millisecondsSinceEpoch,
            ),
          );
        } else {
          // Exists - check if server is newer
          if (goal.updatedAt.isAfter(
            DateTime.fromMillisecondsSinceEpoch(existing.updatedAt),
          )) {
            // Update
            await database.insertOrUpdateGoal(
              GoalTableData(
                id: goal.id,
                name: goal.name,
                targetAmount: goal.targetAmount,
                month: goal.month,
                isSynced: true,
                isDeleted: goal.isDeleted,
                updatedAt: goal.updatedAt.millisecondsSinceEpoch,
              ),
            );
          }
        }
      }

      // Save new sync timestamp
      await prefs.setString(
        'last_sync_timestamp',
        response.serverTime.toUtc().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Pull error: $e');
      rethrow;
    }
  }
}
