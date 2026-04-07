class PasswordModel {
  final String id;
  final String houseId;
  final String name;
  final String value;
  final String category;
  final String? createdBy;
  final String createdAt;

  const PasswordModel({
    required this.id,
    required this.houseId,
    required this.name,
    required this.value,
    required this.category,
    this.createdBy,
    required this.createdAt,
  });

  factory PasswordModel.fromMap(Map<String, dynamic> map) {
    return PasswordModel(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      name: map['name'] as String,
      value: map['value'] as String,
      category: map['category'] as String? ?? 'other',
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
