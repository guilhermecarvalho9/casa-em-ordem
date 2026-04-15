import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory PasswordModel.fromMap(String id, Map<String, dynamic> map) {
    return PasswordModel(
      id: id,
      houseId: map['houseId'] as String? ?? '',
      name: map['name'] as String,
      value: map['value'] as String,
      category: map['category'] as String? ?? 'other',
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : (map['createdAt'] as String? ?? ''),
    );
  }
}
