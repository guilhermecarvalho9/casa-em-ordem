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

  factory DamagedItemModel.fromMap(Map<String, dynamic> map) {
    return DamagedItemModel(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String? ?? '',
      photoUrl: map['photo_url'] as String?,
      status: map['status'] as String? ?? 'pending',
      reportedBy: map['reported_by'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  bool get isPending => status == 'pending';
}
