import 'package:cloud_firestore/cloud_firestore.dart';

class HouseNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String createdBy;
  final DateTime createdAt;
  final List<String> seenBy;

  const HouseNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdBy,
    required this.createdAt,
    required this.seenBy,
  });

  factory HouseNotification.fromMap(String id, Map<String, dynamic> map) {
    return HouseNotification(
      id: id,
      type: map['type'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: List<String>.from(map['seenBy'] as List? ?? []),
    );
  }
}
