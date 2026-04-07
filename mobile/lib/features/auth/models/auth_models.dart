class UserProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final String color;

  const UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.color,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      avatarUrl: map['avatar_url'] as String?,
      color: map['color'] as String? ?? '#2A9D90',
    );
  }

  UserProfile copyWith({
    String? name,
    String? avatarUrl,
    String? color,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      color: color ?? this.color,
    );
  }
}

class House {
  final String id;
  final String name;
  final String? address;
  final String inviteCode;

  const House({
    required this.id,
    required this.name,
    this.address,
    required this.inviteCode,
  });

  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String?,
      inviteCode: map['invite_code'] as String,
    );
  }
}

class HouseMember {
  final String id;
  final String houseId;
  final String userId;
  final String role;
  final String entryDate;

  const HouseMember({
    required this.id,
    required this.houseId,
    required this.userId,
    required this.role,
    required this.entryDate,
  });

  factory HouseMember.fromMap(Map<String, dynamic> map) {
    return HouseMember(
      id: map['id'] as String,
      houseId: map['house_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String? ?? 'member',
      entryDate: map['entry_date'] as String? ?? '',
    );
  }

  bool get isAdmin => role == 'admin';
}
