class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final String month; // Format: YYYY-MM
  final bool isSynced;
  final bool isDeleted;
  final DateTime updatedAt;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.month,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      month: json['month'] as String,
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
    'name': name,
    'targetAmount': targetAmount,
    'month': month,
    'isSynced': isSynced,
    'isDeleted': isDeleted,
    'updatedAt': _msIso(updatedAt),
  };

  Goal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    String? month,
    bool? isSynced,
    bool? isDeleted,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      month: month ?? this.month,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
