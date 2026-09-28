import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Painter for drawing EMVCo QR code without external network calls.
class QrWidgetPainter extends CustomPainter {
  final String data;
  final Color color;
  final Color backgroundColor;

  QrWidgetPainter({
    required this.data,
    this.color = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Draw solid background
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    try {
      final qrCode = QrCode.fromData(
        data: data,
        errorCorrectLevel: QrErrorCorrectLevel.M,
      );
      final qrImage = QrImage(qrCode);
      final moduleSize = size.width / qrImage.moduleCount;
      final modulePaint = Paint()..color = color;

      for (int x = 0; x < qrImage.moduleCount; x++) {
        for (int y = 0; y < qrImage.moduleCount; y++) {
          if (qrImage.isDark(y, x)) {
            canvas.drawRect(
              Rect.fromLTWH(
                x * moduleSize,
                y * moduleSize,
                moduleSize,
                moduleSize,
              ),
              modulePaint,
            );
          }
        }
      }
    } catch (_) {}
  }

  @override
  bool shouldRepaint(covariant QrWidgetPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Reusable offline QR Code widget for VietQR payments.
class VietQrCodeWidget extends StatelessWidget {
  final String payload;
  final double size;
  final Color color;
  final Color backgroundColor;

  const VietQrCodeWidget({
    super.key,
    required this.payload,
    this.size = 200,
    this.color = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (payload.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: const Center(
          child: Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: CustomPaint(
        size: Size(size - 24, size - 24),
        painter: QrWidgetPainter(
          data: payload,
          color: color,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}
