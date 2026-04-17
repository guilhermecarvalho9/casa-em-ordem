import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  final String id;
  final String houseId;
  final String name;
  final String category;
  final double value;
  final String ownerId;
  final String ownerName;
  final String? photoUrl;
  final String? description;
  final String createdBy;
  final String createdAt;

  const InventoryItemModel({
    required this.id,
    required this.houseId,
    required this.name,
    required this.category,
    required this.value,
    required this.ownerId,
    required this.ownerName,
    this.photoUrl,
    this.description,
    required this.createdBy,
    required this.createdAt,
  });

  factory InventoryItemModel.fromMap(String id, String houseId, Map<String, dynamic> map) {
    return InventoryItemModel(
      id: id,
      houseId: houseId,
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'other',
      value: (map['value'] as num?)?.toDouble() ?? 0,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      description: map['description'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String().substring(0, 10)
          : (map['createdAt'] as String? ?? ''),
    );
  }

  bool get isShared => ownerId.isEmpty;
}
