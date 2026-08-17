import 'package:flutter/material.dart';

class DocumentGuideOverlay extends StatelessWidget {
  const DocumentGuideOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _DocumentGuidePainter(),
      ),
    );
  }
}

class _DocumentGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Ukuran panduan dokumen proporsi A4 (1:1.414)
    final padding = size.width * 0.08;
    final guideWidth = size.width - (padding * 2);
    final guideHeight = guideWidth * 1.414;
    
    // Posisi di tengah layar vertikal agak ke atas
    final left = padding;
    final top = (size.height - guideHeight) / 2.2;
    final right = left + guideWidth;
    final bottom = top + guideHeight;

    final guideRect = Rect.fromLTRB(left, top, right, bottom);

    // 1. Semi-transparent background mask di luar kotak panduan
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(guideRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // 2. Corner brackets (Sudut-sudut panduan dokumen)
    final cornerPaint = Paint()
      ..color = const Color(0xFF38BDF8) // Cyan Accent
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + 16)
        ..arcToPoint(Offset(left + 16, top), radius: const Radius.circular(16))
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right - 16, top)
        ..arcToPoint(Offset(right, top + 16), radius: const Radius.circular(16))
        ..lineTo(right, top + cornerLength),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(left, bottom - cornerLength)
        ..lineTo(left, bottom - 16)
        ..arcToPoint(Offset(left + 16, bottom), radius: const Radius.circular(16))
        ..lineTo(left + cornerLength, bottom),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(right - cornerLength, bottom)
        ..lineTo(right - 16, bottom)
        ..arcToPoint(Offset(right, bottom - 16), radius: const Radius.circular(16))
        ..lineTo(right, bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
