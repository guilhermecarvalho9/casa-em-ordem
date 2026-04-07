import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class MemberAvatar extends StatelessWidget {
  final String name;
  final String color;
  final double radius;

  const MemberAvatar({
    super.key,
    required this.name,
    required this.color,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = AppColors.memberColorFromHex(color);
    final initials = _getInitials(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
