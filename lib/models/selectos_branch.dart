class SelectosBranch {
  final String id;
  final String name;
  final String address;
  final String zoneId;
  final String department;
  final String municipality;

  const SelectosBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.zoneId,
    this.department = '',
    this.municipality = '',
  });

  factory SelectosBranch.fromJson(Map<String, dynamic> json) {
    return SelectosBranch(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      zoneId: json['zoneId']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      municipality: json['municipality']?.toString() ?? '',
    );
  }
}
