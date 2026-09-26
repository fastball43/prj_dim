/// T4 연결 잇기(Trail Making) 버블 배치
///
/// 캔버스를 격자로 나눠 버블마다 서로 다른 칸을 무작위로 배정하고,
/// 칸 안에서 약간 흔들어(jitter) 배치한다.
/// - 화면 크기와 관계없이 항상 [count]개 위치를 반환 (무작위 재시도 방식의 실패 없음)
/// - 칸이 작으면 버블 반지름을 줄여 겹치지 않게 함
/// - 모든 버블은 캔버스 안에 완전히 들어감
library trail_layout;

import 'dart:math';

/// 기본 버블 반지름 (px).
const double kTrailBubbleRadius = 28.0;

/// 최소 버블 반지름 (px). 이보다 작으면 탭하기 어렵다.
const double kTrailMinBubbleRadius = 14.0;

/// 버블 사이 최소 여백 (px).
const double kTrailBubbleGap = 8.0;

/// 버블 배치 결과.
class TrailLayout {
  /// 버블 중심 좌표 (px). 레이블 순서와 동일.
  final List<Point<double>> centers;

  /// 버블 반지름 (px).
  final double radius;

  const TrailLayout({required this.centers, required this.radius});
}

/// [count]개 버블을 [width]×[height] 캔버스에 배치.
///
/// [random]: 테스트용 시드 주입
TrailLayout generateTrailLayout({
  required int count,
  required double width,
  required double height,
  double maxRadius = kTrailBubbleRadius,
  Random? random,
}) {
  assert(count > 0, 'count must be > 0');
  final rand = random ?? Random();
  final w = max(width, 1.0);
  final h = max(height, 1.0);

  // 칸 모양이 정사각형에 가깝도록 열·행 수 결정
  var cols = max(1, sqrt(count * w / h).round());
  var rows = (count / cols).ceil();
  // 여유 칸을 하나 이상 두어 배치가 매번 달라지게 함
  if (cols * rows == count) {
    if (w / cols >= h / rows) {
      cols++;
    } else {
      rows++;
    }
  }

  final cellW = w / cols;
  final cellH = h / rows;
  final radius = min(
    maxRadius,
    max(kTrailMinBubbleRadius, (min(cellW, cellH) - kTrailBubbleGap) / 2),
  );

  // 칸 안에서 흔들 수 있는 범위 (버블 + 여백이 칸을 벗어나지 않게)
  final jitterX = max(0.0, cellW / 2 - radius - kTrailBubbleGap / 2);
  final jitterY = max(0.0, cellH / 2 - radius - kTrailBubbleGap / 2);

  final cells = List.generate(cols * rows, (i) => i)..shuffle(rand);
  final centers = <Point<double>>[];
  for (final cell in cells.take(count)) {
    final cx = (cell % cols + 0.5) * cellW;
    final cy = (cell ~/ cols + 0.5) * cellH;
    final x = cx + (rand.nextDouble() * 2 - 1) * jitterX;
    final y = cy + (rand.nextDouble() * 2 - 1) * jitterY;
    // 칸이 버블보다 작을 때도 캔버스 밖으로 나가지 않게 보정
    centers.add(Point(
      x.clamp(min(radius, w / 2), max(w - radius, w / 2)),
      y.clamp(min(radius, h / 2), max(h - radius, h / 2)),
    ));
  }

  return TrailLayout(centers: centers, radius: radius);
}
