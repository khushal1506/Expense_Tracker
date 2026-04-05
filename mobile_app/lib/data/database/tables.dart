import 'package:drift/drift.dart';

class TransactionTable extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()(); // INCOME, EXPENSE
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer()(); // Unix timestamp in milliseconds

  @override
  Set<Column> get primaryKey => {id};
}

class GoalTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get targetAmount => real()();
  TextColumn get month => text()(); // Format: "YYYY-MM"
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer()(); // Unix timestamp in milliseconds

  @override
  Set<Column> get primaryKey => {id};
}
