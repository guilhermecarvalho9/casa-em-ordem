import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory RuleModel.fromMap(String id, Map<String, dynamic> map) {
    return RuleModel(
      id: id,
      houseId: map['houseId'] as String? ?? '',
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : (map['createdAt'] as String? ?? ''),
    );
  }
}
