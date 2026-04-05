class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? notes;
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] == 'INCOME'
          ? TransactionType.income
          : TransactionType.expense,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Formats [dt] as UTC ISO-8601 with exactly 3 fractional (ms) digits.
  static String _msIso(DateTime dt) {
    final u = dt.toUtc();
    final ms = u.millisecond.toString().padLeft(3, '0');
    return '${u.year.toString().padLeft(4, '0')}-'
        '${u.month.toString().padLeft(2, '0')}-'
        '${u.day.toString().padLeft(2, '0')}T'
        '${u.hour.toString().padLeft(2, '0')}:'
        '${u.minute.toString().padLeft(2, '0')}:'
        '${u.second.toString().padLeft(2, '0')}'
        '.$ms'
        'Z';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'type': type == TransactionType.income ? 'INCOME' : 'EXPENSE',
    'category': category,
    'date': date.toIso8601String().split('T')[0],
    'notes': notes,
    'isSynced': isSynced,
    'isDeleted': isDeleted,
    'updatedAt': _msIso(updatedAt),
  };

  Transaction copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? notes,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum TransactionType { income, expense }
