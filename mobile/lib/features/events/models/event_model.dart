import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String houseId;
  final String title;
  final String? description;
  final String eventDate;
  final String? eventTime;
  final String? location;
  final String? createdBy;
  final String createdAt;

  const EventModel({
    required this.id,
    required this.houseId,
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    this.location,
    this.createdBy,
    required this.createdAt,
  });

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      houseId: map['houseId'] as String? ?? '',
      title: map['title'] as String,
      description: map['description'] as String?,
      eventDate: map['eventDate'] as String,
      eventTime: map['eventTime'] as String?,
      location: map['location'] as String?,
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : (map['createdAt'] as String? ?? ''),
    );
  }
}
