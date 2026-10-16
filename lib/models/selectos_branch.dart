class SelectosBranch {
  final String id;
  final String name;
  final String address;
  final String zoneId;

  const SelectosBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.zoneId,
  });

  factory SelectosBranch.fromJson(Map<String, dynamic> json) {
    return SelectosBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      zoneId: json['zoneId']?.toString() ?? '',
    );
  }
}
