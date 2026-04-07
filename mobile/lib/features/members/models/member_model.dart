class MemberModel {
  final String id;
  final String houseId;
  final String userId;
  final String role;
  final String entryDate;
  // From profiles join
  final String name;
  final String? avatarUrl;
  final String color;

  const MemberModel({
    required this.id,
    required this.houseId,
    required this.userId,
    required this.role,
    required this.entryDate,
    required this.name,
    this.avatarUrl,
    required this.color,
  });

  factory MemberModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return MemberModel(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String? ?? 'member',
      entryDate: map['entry_date'] as String? ?? '',
      name: profile?['name'] as String? ?? 'Membro',
      avatarUrl: profile?['avatar_url'] as String?,
      color: profile?['color'] as String? ?? '#2A9D90',
    );
  }

  bool get isAdmin => role == 'admin';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
