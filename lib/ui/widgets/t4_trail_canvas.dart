import 'dart:math';
import 'package:flutter/material.dart';

/// Trail Making Test 캔버스 위젯.
///
/// [labels]: 화면에 표시되는 버블 레이블 (탭 순서와 동일)
/// [onComplete]: 모든 버블을 올바른 순서로 탭했을 때 호출. 경과 시간(초) 전달.
class T4TrailCanvas extends StatefulWidget {
  final List<String> labels;
  final void Function(double elapsedSeconds) onComplete;

  const T4TrailCanvas({
    super.key,
    required this.labels,
    required this.onComplete,
  });

  @override
  State<T4TrailCanvas> createState() => _T4TrailCanvasState();
}

class _T4TrailCanvasState extends State<T4TrailCanvas> {
  late List<Offset> _positions; // 정규화 좌표 (0-1)
  late List<bool> _tapped;
  int _nextIndex = 0;
  DateTime? _startTime;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _tapped = List.filled(widget.labels.length, false);
  }

  void _generatePositions(Size size) {
    if (_ready) return;
    _positions = _generateNonOverlapping(widget.labels.length, size);
    _ready = true;
  }

  static List<Offset> _generateNonOverlapping(int count, Size canvasSize) {
    final rand = Random();
    const bubbleRadius = 28.0;
    const minDist = 70.0;
    const margin = bubbleRadius + 8;

    final positions = <Offset>[];
    int tries = 0;
    while (positions.length < count && tries < 2000) {
      tries++;
      final x = margin + rand.nextDouble() * (canvasSize.width - 2 * margin);
      final y = margin + rand.nextDouble() * (canvasSize.height - 2 * margin);
      final p = Offset(x, y);
      if (positions.every((q) => (p - q).distance >= minDist)) {
        positions.add(p);
      }
    }
    return positions;
  }

  void _onTap(int index) {
    if (index != _nextIndex) return;
    if (_nextIndex == 0) _startTime = DateTime.now();

    setState(() {
      _tapped[index] = true;
      _nextIndex++;
    });

    if (_nextIndex == widget.labels.length) {
      final elapsed =
          DateTime.now().difference(_startTime!).inMilliseconds / 1000.0;
      widget.onComplete(elapsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextLabel =
        _nextIndex < widget.labels.length ? widget.labels[_nextIndex] : null;

    return Column(
      children: [
        if (nextLabel != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                children: [
                  const TextSpan(text: '다음: '),
                  TextSpan(
                    text: nextLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size =
                  Size(constraints.maxWidth, constraints.maxHeight);
              _generatePositions(size);

              return Stack(
                children: [
                  // Connection lines
                  CustomPaint(
                    size: size,
                    painter: _LinePainter(
                      positions: _positions,
                      tappedCount: _nextIndex,
                    ),
                  ),
                  // Bubbles
                  ..._buildBubbles(context),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBubbles(BuildContext context) {
    const r = 28.0;
    final primary = Theme.of(context).colorScheme.primary;

    return List.generate(widget.labels.length, (i) {
      final pos = _positions[i];
      final tapped = _tapped[i];
      final isNext = i == _nextIndex;

      final bgColor = tapped
          ? Colors.green.shade200
          : isNext
              ? primary
              : Colors.white;
      final borderColor = tapped
          ? Colors.green.shade600
          : isNext
              ? primary
              : Colors.grey.shade400;
      final textColor = (tapped || isNext) ? Colors.white : Colors.black87;
      if (tapped) {}

      return Positioned(
        left: pos.dx - r,
        top: pos.dy - r,
        child: GestureDetector(
          onTap: () => _onTap(i),
          child: Container(
            width: r * 2,
            height: r * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.labels[i],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: widget.labels[i].length > 2 ? 11 : 15,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _LinePainter extends CustomPainter {
  final List<Offset> positions;
  final int tappedCount;

  const _LinePainter({required this.positions, required this.tappedCount});

  @override
  void paint(Canvas canvas, Size size) {
    if (tappedCount < 2) return;
    final paint = Paint()
      ..color = Colors.green.shade400
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < tappedCount - 1; i++) {
      canvas.drawLine(positions[i], positions[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.tappedCount != tappedCount;
}
