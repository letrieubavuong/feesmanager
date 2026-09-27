import 'package:flutter/material.dart';

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
      bg = Colors.indigo.shade50;
      fg = Colors.indigo.shade700;
    } else if (gender == 'NU') {
      iconData = Icons.face_2_outlined;
      bg = Colors.pink.shade50;
      fg = Colors.pink.shade700;
    } else {
      iconData = Icons.person_outline_rounded;
      bg = Colors.grey.shade200;
      fg = Colors.blueGrey.shade700;
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Icon(iconData, size: radius * 1.1, color: fg),
    );
  }
}
