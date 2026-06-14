import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String id;
  final String houseId;
  final String userId;
  final String role;
  final String entryDate;
  final String name;
  final String? avatarUrl;
  final String color;
  final String? expiresAt;
  final String? phone;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? countryCode;

  const MemberModel({
    required this.id,
    required this.houseId,
    required this.userId,
    required this.role,
    required this.entryDate,
    required this.name,
    this.avatarUrl,
    required this.color,
    this.expiresAt,
    this.phone,
    this.emergencyContact,
    this.emergencyPhone,
    this.countryCode,
  });

  factory MemberModel.fromMap(String memberId, String houseId, Map<String, dynamic> map) {
    return MemberModel(
      id: memberId,
      houseId: houseId,
      userId: map['userId'] as String? ?? memberId,
      role: map['role'] as String? ?? 'member',
      entryDate: map['entryDate'] is Timestamp
          ? (map['entryDate'] as Timestamp).toDate().toIso8601String().substring(0, 10)
          : (map['entryDate'] as String? ?? ''),
      name: map['name'] as String? ?? 'Membro',
      avatarUrl: map['avatarUrl'] as String?,
      color: map['color'] as String? ?? '#2A9D90',
      expiresAt: map['expiresAt'] as String?,
      phone: map['phone'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      emergencyPhone: map['emergencyPhone'] as String?,
      countryCode: map['countryCode'] as String?,
    );
  }

  bool get isAdmin => role == 'admin';

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
