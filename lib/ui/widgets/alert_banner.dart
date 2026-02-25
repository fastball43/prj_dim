import 'package:flutter/material.dart';
import '../../core/algorithms/change_detection.dart';

/// 인지 점수 변화 감지 경고 배너.
class AlertBanner extends StatelessWidget {
  final ChangeDetectionResult result;

  const AlertBanner({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.alert) {
      return _Banner(
        color: Colors.red.shade50,
        borderColor: Colors.red.shade300,
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.red.shade700,
        title: '인지 기능 변화가 감지되었습니다',
        body: '기준선 대비 ${(result.baseline! - result.latestScore!).toStringAsFixed(1)}점 하락이 2회 연속 확인되었습니다. 전문의 상담을 권장합니다.',
      );
    }
    if (result.recommendReset) {
      return _Banner(
        color: Colors.amber.shade50,
        borderColor: Colors.amber.shade400,
        icon: Icons.access_time_rounded,
        iconColor: Colors.amber.shade800,
        title: '3개월 이상 경과했습니다',
        body: '마지막 인지 테스트 이후 90일이 지났습니다. 새 기준선 측정을 시작하세요.',
      );
    }
    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _Banner({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: iconColor)),
                const SizedBox(height: 4),
                Text(body,
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
