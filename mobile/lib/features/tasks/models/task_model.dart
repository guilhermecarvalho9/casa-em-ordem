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
  });

  factory TaskModel.fromMap(String id, Map<String, dynamic> map) {
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
    );
  }
}
