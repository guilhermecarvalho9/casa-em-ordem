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

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      assignedTo: map['assigned_to'] as String?,
      dueDate: map['due_date'] as String?,
      completed: map['completed'] as bool? ?? false,
      recurring: map['recurring'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
