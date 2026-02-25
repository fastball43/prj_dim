import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 원형 점수 표시 위젯.
class ScoreRing extends StatelessWidget {
  final double? score;
  final double size;
  final double strokeWidth;
  final String label;

  const ScoreRing({
    super.key,
    required this.score,
    required this.label,
    this.size = 140,
    this.strokeWidth = 10,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = score != null;
    final color = hasData ? AppTheme.scoreColor(score!) : Colors.grey.shade300;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(
              progress: hasData ? score! / 100 : 0,
              color: color,
              strokeWidth: strokeWidth,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasData ? score!.toStringAsFixed(0) : '--',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                hasData ? AppTheme.scoreTierLabel(score!) : '미측정',
                style: TextStyle(
                  fontSize: size * 0.10,
                  color: hasData ? color : Colors.grey,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: size * 0.09,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
