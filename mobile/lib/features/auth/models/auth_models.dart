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
  // Structured address
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  // Property info
  final int? bedrooms;
  final int? bathrooms;
  final int? garage;
  final bool hasPool;
  final bool allowsPets;
  // Contract
  final String? contractType;
  final String? contractExpiry;

  const House({
    required this.id,
    required this.name,
    this.address,
    required this.inviteCode,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.bedrooms,
    this.bathrooms,
    this.garage,
    this.hasPool = false,
    this.allowsPets = false,
    this.contractType,
    this.contractExpiry,
  });

  factory House.fromMap(String id, Map<String, dynamic> map) {
    return House(
      id: id,
      name: map['name'] as String,
      address: map['address'] as String?,
      inviteCode: map['inviteCode'] as String,
      street: map['street'] as String?,
      number: map['number'] as String?,
      complement: map['complement'] as String?,
      neighborhood: map['neighborhood'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      country: map['country'] as String?,
      zipCode: map['zipCode'] as String?,
      bedrooms: (map['bedrooms'] as num?)?.toInt(),
      bathrooms: (map['bathrooms'] as num?)?.toInt(),
      garage: (map['garage'] as num?)?.toInt(),
      hasPool: map['hasPool'] as bool? ?? false,
      allowsPets: map['allowsPets'] as bool? ?? false,
      contractType: map['contractType'] as String?,
      contractExpiry: map['contractExpiry'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    if (address != null) 'address': address,
    'inviteCode': inviteCode,
  };

  String get structuredAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) {
      parts.add(number != null && number!.isNotEmpty ? '$street, $number' : street!);
    }
    if (complement != null && complement!.isNotEmpty) parts.add(complement!);
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add(neighborhood!);
    if (city != null && city!.isNotEmpty) {
      parts.add(state != null && state!.isNotEmpty ? '$city - $state' : city!);
    }
    if (zipCode != null && zipCode!.isNotEmpty) parts.add('CEP $zipCode');
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  String get displayAddress {
    final s = structuredAddress;
    return s.isNotEmpty ? s : (address ?? '');
  }
}

class HouseMember {
  final String id;
  final String houseId;
  final String userId;
  final String role;
  final String entryDate;
  final String? expiresAt;
  final String? phone;
  final String? emergencyContact;
  final String? emergencyPhone;

  const HouseMember({
    required this.id,
    required this.houseId,
    required this.userId,
    required this.role,
    required this.entryDate,
    this.expiresAt,
    this.phone,
    this.emergencyContact,
    this.emergencyPhone,
  });

  factory HouseMember.fromMap(String memberId, String houseId, Map<String, dynamic> map) {
    return HouseMember(
      id: memberId,
      houseId: houseId,
      userId: map['userId'] as String? ?? memberId,
      role: map['role'] as String? ?? 'member',
      entryDate: map['entryDate'] as String? ?? '',
      expiresAt: map['expiresAt'] as String?,
      phone: map['phone'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      emergencyPhone: map['emergencyPhone'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isOwner => role == 'owner';
  bool get canEditHouse => role == 'admin' || role == 'owner';

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
