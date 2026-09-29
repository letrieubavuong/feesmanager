import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/app_theme.dart';

/// Compact actions shared by student cards. Only the parent phone is used.
class ParentContactActions extends StatelessWidget {
  final String? phone;

  const ParentContactActions({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    final number = phone?.trim() ?? '';
    final zaloNumber = number.replaceAll(RegExp(r'[^0-9]'), '');
    final callable = number.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _action(
          context,
          icon: Icons.call_outlined,
          label: 'Gọi',
          tooltip: 'Gọi phụ huynh',
          enabled: callable,
          uri: Uri(scheme: 'tel', path: number),
        ),
        const SizedBox(width: 4),
        _action(
          context,
          icon: Icons.chat_bubble_outline,
          label: 'Zalo',
          tooltip: 'Mở Zalo phụ huynh',
          enabled: zaloNumber.isNotEmpty,
          uri: Uri.https('zalo.me', '/$zaloNumber'),
        ),
      ],
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String tooltip,
    required bool enabled,
    required Uri uri,
  }) {
    return SizedBox(
      height: 30,
      child: OutlinedButton(
        onPressed: enabled ? () => _open(context, uri) : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: const Size(0, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          foregroundColor: AppColors.cyanAccent,
          side: const BorderSide(color: AppColors.border),
        ),
        child: Tooltip(
          message: tooltip,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14),
              const SizedBox(width: 3),
              Text(label, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // The device may not have a handler for this URI.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở liên kết trên thiết bị này.'),
        ),
      );
    }
  }
}
