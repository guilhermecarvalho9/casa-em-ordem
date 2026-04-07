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

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      eventDate: map['event_date'] as String,
      eventTime: map['event_time'] as String?,
      location: map['location'] as String?,
      createdBy: map['created_by'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
