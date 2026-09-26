import 'package:flutter/material.dart';

import '../../core/algorithms/trail_layout.dart';

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
  List<Offset>? _normalized; // 정규화 좌표 (0-1). 화면 크기가 바뀌어도 비율 유지
  double _radius = kTrailBubbleRadius;
  late List<bool> _tapped;
  int _nextIndex = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _tapped = List.filled(widget.labels.length, false);
  }

  /// 최초 레이아웃 크기로 한 번만 배치하고, 이후에는 현재 크기에 맞춰 변환.
  List<Offset> _positionsFor(Size size) {
    if (_normalized == null) {
      final layout = generateTrailLayout(
        count: widget.labels.length,
        width: size.width,
        height: size.height,
      );
      _radius = layout.radius;
      _normalized = layout.centers
          .map((p) => Offset(p.x / size.width, p.y / size.height))
          .toList();
    }
    return _normalized!
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();
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
              final positions = _positionsFor(size);

              return Stack(
                children: [
                  // Connection lines
                  CustomPaint(
                    size: size,
                    painter: _LinePainter(
                      positions: positions,
                      tappedCount: _nextIndex,
                    ),
                  ),
                  // Bubbles
                  ..._buildBubbles(context, positions),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBubbles(BuildContext context, List<Offset> positions) {
    final r = _radius;

    return List.generate(widget.labels.length, (i) {
      final pos = positions[i];
      final tapped = _tapped[i];

      final bgColor = tapped ? Colors.green.shade200 : Colors.white;
      final borderColor =
          tapped ? Colors.green.shade600 : Colors.grey.shade400;
      final textColor = tapped ? Colors.white : Colors.black87;

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
                fontSize: (widget.labels[i].length > 2 ? 0.4 : 0.54) * r,
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
