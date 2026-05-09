import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class MemberAvatar extends StatelessWidget {
  final String name;
  final String color;
  final double radius;
  final String? avatarUrl;

  const MemberAvatar({
    super.key,
    required this.name,
    required this.color,
    this.radius = 20,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.memberColorFromHex(color);
    final initials = _getInitials(name);

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => _Initials(initials: initials, radius: radius, bgColor: bgColor),
            errorWidget: (_, __, ___) => _Initials(initials: initials, radius: radius, bgColor: bgColor),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: _Initials(initials: initials, radius: radius, bgColor: bgColor),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

class _Initials extends StatelessWidget {
  final String initials;
  final double radius;
  final Color bgColor;

  const _Initials({required this.initials, required this.radius, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Text(
      initials,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: radius * 0.65,
      ),
    );
  }
}
