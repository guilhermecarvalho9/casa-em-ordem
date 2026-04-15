import 'package:cloud_firestore/cloud_firestore.dart';

class DamagedItemModel {
  final String id;
  final String houseId;
  final String title;
  final String? description;
  final String location;
  final String? photoUrl;
  final String status;
  final String? reportedBy;
  final String createdAt;

  const DamagedItemModel({
    required this.id,
    required this.houseId,
    required this.title,
    this.description,
    required this.location,
    this.photoUrl,
    required this.status,
    this.reportedBy,
    required this.createdAt,
  });

  factory DamagedItemModel.fromMap(String id, Map<String, dynamic> map) {
    return DamagedItemModel(
      id: id,
      houseId: map['houseId'] as String? ?? '',
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      status: map['status'] as String? ?? 'pending',
      reportedBy: map['reportedBy'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : (map['createdAt'] as String? ?? ''),
    );
  }

  bool get isPending => status == 'pending';
}
