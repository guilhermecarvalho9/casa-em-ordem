class RuleModel {
  final String id;
  final String houseId;
  final String title;
  final String description;
  final String? createdBy;
  final String createdAt;

  const RuleModel({
    required this.id,
    required this.houseId,
    required this.title,
    required this.description,
    this.createdBy,
    required this.createdAt,
  });

  factory RuleModel.fromMap(Map<String, dynamic> map) {
    return RuleModel(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
