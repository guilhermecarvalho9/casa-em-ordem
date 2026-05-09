import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String houseId;
  final String title;
  final String? description;
  final String? assignedTo;
  final String? dueDate;
  final bool completed;
  final String? recurring;
  final String? createdBy;
  final String createdAt;
  final bool photoRequired;
  final List<String> photosBefore;
  final List<String> photosAfter;

  const TaskModel({
    required this.id,
    required this.houseId,
    required this.title,
    this.description,
    this.assignedTo,
    this.dueDate,
    required this.completed,
    this.recurring,
    this.createdBy,
    required this.createdAt,
    this.photoRequired = false,
    this.photosBefore = const [],
    this.photosAfter = const [],
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
    List<String> toStringList(dynamic v) {
      if (v is List) return v.whereType<String>().toList();
      return [];
    }

    return TaskModel(
      id: id,
      houseId: map['houseId'] as String? ?? '',
      title: map['title'] as String,
      description: map['description'] as String?,
      assignedTo: map['assignedTo'] as String?,
      dueDate: map['dueDate'] as String?,
      completed: map['completed'] as bool? ?? false,
      recurring: map['recurring'] as String?,
      createdBy: map['createdBy'] as String?,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate().toIso8601String()
          : (map['createdAt'] as String? ?? ''),
      photoRequired: map['photoRequired'] as bool? ?? false,
      photosBefore: toStringList(map['photosBefore']),
      photosAfter: toStringList(map['photosAfter']),
    );
  }
}
