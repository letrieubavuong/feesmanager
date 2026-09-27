import 'package:flutter/material.dart';
import '../design_system/app_theme.dart';

class StudentAvatar extends StatelessWidget {
  final String? gioiTinh;
  final double radius;
  final String? studentName;

  const StudentAvatar({
    super.key,
    this.gioiTinh,
    this.radius = 20.0,
    this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final gender = gioiTinh?.trim().toUpperCase();

    IconData iconData;
    Color bg;
    Color fg;

    if (gender == 'NAM') {
      iconData = Icons.face_5_outlined;
      bg = const Color(0x260A84FF);
      fg = const Color(0xFF22B8F3);
    } else if (gender == 'NU') {
      iconData = Icons.face_2_outlined;
      bg = const Color(0x26F472B6);
      fg = const Color(0xFFF472B6);
    } else {
      iconData = Icons.person_outline_rounded;
      bg = const Color(0x26728DA4);
      fg = AppColors.textSecondary;
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Icon(iconData, size: radius * 1.1, color: fg),
    );
  }
}
