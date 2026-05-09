import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String houseId;
  final String title;
  final String? description;
  final String eventDate;
  final String? eventTime;
  final String? eventEndTime;
  final String? location;
  final String? createdBy;
  final String createdAt;
  final String? recurring;
  final String? recurringUntil;
  // Runtime-only — not persisted to Firestore
  final bool isVirtual;
  final String? baseId;

  const EventModel({
    required this.id,
    required this.houseId,
    required this.title,
    this.description,
    required this.eventDate,
    this.eventTime,
    this.eventEndTime,
    this.location,
    this.createdBy,
    required this.createdAt,
    this.recurring,
    this.recurringUntil,
    this.isVirtual = false,
    this.baseId,
  });

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      houseId: map['houseId'] as String? ?? '',
      title: map['title'] as String,
      description: map['description'] as String?,
      eventDate: map['eventDate'] as String,
      eventTime: map['eventTime'] as String?,
      eventEndTime: map['eventEndTime'] as String?,
      location: map['location'] as String?,
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : (map['createdAt'] as String? ?? ''),
      recurring: map['recurring'] as String?,
      recurringUntil: map['recurringUntil'] as String?,
    );
  }

  EventModel asVirtualOccurrence(String newId, String newDate) {
    return EventModel(
      id: newId,
      houseId: houseId,
      title: title,
      description: description,
      eventDate: newDate,
      eventTime: eventTime,
      eventEndTime: eventEndTime,
      location: location,
      createdBy: createdBy,
      createdAt: createdAt,
      recurring: recurring,
      recurringUntil: recurringUntil,
      isVirtual: true,
      baseId: id,
    );
  }
}
