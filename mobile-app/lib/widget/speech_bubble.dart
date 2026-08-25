import 'package:flutter/material.dart';

class SpeechBubble extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const SpeechBubble({
    Key? key,
    required this.color,
    this.width = 120,
    this.height = 90,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SpeechBubblePainter(color),
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  final Color color;

  _SpeechBubblePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Main oval
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.85),
        Radius.circular(size.height),
      ),
    );

    // Tail
    path.moveTo(size.width * 0.25, size.height * 0.85);
    path.lineTo(size.width * 0.18, size.height);
    path.lineTo(size.width * 0.35, size.height * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
