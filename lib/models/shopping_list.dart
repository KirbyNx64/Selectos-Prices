class ShoppingList {
  final int id;
  final String? name;
  final DateTime createdAt;

  const ShoppingList({
    required this.id,
    required this.createdAt,
    this.name,
  });

  String get displayName {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
    return 'Lista de compras';
  }

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
      name: map['name'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
