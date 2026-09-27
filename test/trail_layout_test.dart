import 'dart:math';

import 'package:test/test.dart';
import 'package:prj_dim/core/algorithms/trail_layout.dart';

void main() {
  /// 모든 버블이 캔버스 안에 있고 서로 겹치지 않는지 검사.
  void expectValidLayout(TrailLayout layout, int count, double w, double h) {
    expect(layout.centers.length, equals(count));
    final r = layout.radius;
    for (final c in layout.centers) {
      expect(c.x, inInclusiveRange(r - 1e-9, w - r + 1e-9));
      expect(c.y, inInclusiveRange(r - 1e-9, h - r + 1e-9));
    }
    for (int i = 0; i < count; i++) {
      for (int j = i + 1; j < count; j++) {
        expect(layout.centers[i].distanceTo(layout.centers[j]),
            greaterThanOrEqualTo(2 * r),
            reason: 'bubbles $i and $j overlap');
      }
    }
  }

  group('generateTrailLayout', () {
    test('일반 폰 화면 (360×500) → 10개, 기본 반지름, 겹침 없음', () {
      for (int seed = 0; seed < 200; seed++) {
        final layout = generateTrailLayout(
            count: 10, width: 360, height: 500, random: Random(seed));
        expect(layout.radius, equals(kTrailBubbleRadius));
        expectValidLayout(layout, 10, 360, 500);
      }
    });

    test('작은 화면 (200×200) → 항상 10개, 반지름 축소, 겹침 없음', () {
      for (int seed = 0; seed < 200; seed++) {
        final layout = generateTrailLayout(
            count: 10, width: 200, height: 200, random: Random(seed));
        expect(layout.radius, lessThan(kTrailBubbleRadius));
        expect(layout.radius, greaterThanOrEqualTo(kTrailMinBubbleRadius));
        expectValidLayout(layout, 10, 200, 200);
      }
    });

    test('가로 모드 (700×220) → 10개, 겹침 없음', () {
      for (int seed = 0; seed < 200; seed++) {
        final layout = generateTrailLayout(
            count: 10, width: 700, height: 220, random: Random(seed));
        expectValidLayout(layout, 10, 700, 220);
      }
    });

    test('극단적으로 작은 캔버스에서도 개수는 보장 (예외 없음)', () {
      final layout = generateTrailLayout(
          count: 10, width: 100, height: 60, random: Random(1));
      expect(layout.centers.length, equals(10));
      expect(layout.radius, equals(kTrailMinBubbleRadius));
    });

    test('크기 0 캔버스 → 예외 없이 10개 반환', () {
      final layout = generateTrailLayout(count: 10, width: 0, height: 0);
      expect(layout.centers.length, equals(10));
    });

    test('시드가 다르면 배치가 달라짐', () {
      final a = generateTrailLayout(
          count: 10, width: 360, height: 500, random: Random(1));
      final b = generateTrailLayout(
          count: 10, width: 360, height: 500, random: Random(2));
      expect(a.centers, isNot(equals(b.centers)));
    });
  });
}
