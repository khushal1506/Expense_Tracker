import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database/app_database.dart';
import '../data/model/transaction_model.dart';
import '../data/remote/api_client.dart';
import 'core_providers.dart';

class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final ApiClient apiClient;
  final AppDatabase database;

  TransactionNotifier(this.apiClient, this.database)
    : super(const AsyncValue.loading()) {
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await database.getAllTransactions();
      state = AsyncValue.data(
        transactions.map((t) {
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
        }).toList(),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      // First save to local DB
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
          isSynced: false,
          isDeleted: false,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await _loadTransactions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await database.softDeleteTransaction(id);
      await _loadTransactions();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
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
          isSynced: false,
          isDeleted: false,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await _loadTransactions();
    } catch (e) {
      rethrow;
    }
  }
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>((
      ref,
    ) {
      final apiClient = ref.watch(apiClientProvider);
      final database = ref.watch(databaseProvider);
      return TransactionNotifier(apiClient, database);
    });
