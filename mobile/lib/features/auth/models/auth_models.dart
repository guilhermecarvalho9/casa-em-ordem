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

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['name'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
      color: map['color'] as String? ?? '#2A9D90',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'color': color,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
  };

  UserProfile copyWith({String? name, String? avatarUrl, String? color}) {
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

  factory House.fromMap(String id, Map<String, dynamic> map) {
    return House(
      id: id,
      name: map['name'] as String,
      address: map['address'] as String?,
      inviteCode: map['inviteCode'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (address != null) 'address': address,
    'inviteCode': inviteCode,
  };
}

class HouseMember {
  final String id;
  final String houseId;
  final String userId;
  final String role;
  final String entryDate;
  final String? expiresAt;

  const HouseMember({
    required this.id,
    required this.houseId,
    required this.userId,
    required this.role,
    required this.entryDate,
    this.expiresAt,
  });

  factory HouseMember.fromMap(String memberId, String houseId, Map<String, dynamic> map) {
    return HouseMember(
      id: memberId,
      houseId: houseId,
      userId: map['userId'] as String? ?? memberId,
      role: map['role'] as String? ?? 'member',
      entryDate: map['entryDate'] as String? ?? '',
      expiresAt: map['expiresAt'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';

  bool get isExpired {
    if (expiresAt == null || expiresAt!.isEmpty) return false;
    try {
      final expiry = DateTime.parse(expiresAt!);
      final endOfDay = DateTime(expiry.year, expiry.month, expiry.day, 23, 59, 59);
      return DateTime.now().isAfter(endOfDay);
    } catch (_) {
      return false;
    }
  }
}
