class ShoppingList {
  final int id;
  final DateTime createdAt;

  const ShoppingList({required this.id, required this.createdAt});

  String get dateTimeLabel {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$day/$month/${createdAt.year} · $hour:$minute';
  }

  factory ShoppingList.fromMap(Map<String, Object?> map) {
    return ShoppingList(
      id: map['id'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
