import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [TransactionTable, GoalTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Transaction DAOs
  Future<void> insertOrUpdateTransaction(
    Insertable<TransactionTableData> transaction,
  ) {
    return into(
      transactionTable,
    ).insert(transaction, onConflict: DoUpdate((old) => transaction));
  }

  Future<void> softDeleteTransaction(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(transactionTable)..where((t) => t.id.equals(id))).write(
      TransactionTableCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<TransactionTableData>> getAllTransactions() {
    return (select(
      transactionTable,
    )..where((t) => t.isDeleted.equals(false))).get();
  }

  Future<List<TransactionTableData>> getUnsyncedTransactions() {
    return (select(transactionTable)
          ..where((t) => t.isSynced.equals(false) & t.isDeleted.equals(false)))
        .get();
  }

  Future<void> upsertTransactionsFromServer(
    List<Insertable<TransactionTableData>> transactions,
  ) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(transactionTable, transactions);
    });
  }

  Future<TransactionTableData?> getTransactionById(String id) {
    return (select(
      transactionTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  // Goal DAOs
  Future<void> insertOrUpdateGoal(Insertable<GoalTableData> goal) {
    return into(goalTable).insert(goal, onConflict: DoUpdate((old) => goal));
  }

  Future<void> softDeleteGoal(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (update(goalTable)..where((g) => g.id.equals(id))).write(
      GoalTableCompanion(
        isDeleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<GoalTableData>> getAllGoals() {
    return (select(goalTable)..where((g) => g.isDeleted.equals(false))).get();
  }

  Future<List<GoalTableData>> getUnsyncedGoals() {
    return (select(goalTable)
          ..where((g) => g.isSynced.equals(false) & g.isDeleted.equals(false)))
        .get();
  }

  Future<void> upsertGoalsFromServer(
    List<Insertable<GoalTableData>> goals,
  ) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(goalTable, goals);
    });
  }

  Future<GoalTableData?> getGoalById(String id) {
    return (select(goalTable)..where((g) => g.id.equals(id))).getSingleOrNull();
  }

  // Mark all as synced after successful push
  Future<void> markTransactionsAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(transactionTable)..where((t) => t.id.isIn(ids))).write(
      const TransactionTableCompanion(isSynced: Value(true)),
    );
  }

  Future<void> markGoalsAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    await (update(goalTable)..where((g) => g.id.isIn(ids))).write(
      const GoalTableCompanion(isSynced: Value(true)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    return driftDatabase(name: 'app_db');
  });
}
