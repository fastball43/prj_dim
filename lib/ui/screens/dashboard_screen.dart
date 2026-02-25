import 'package:flutter/material.dart';
import '../../core/algorithms/lifestyle_scoring.dart';
import '../../models/dashboard_state.dart';
import '../../services/cognitive_service.dart';
import '../../services/lifestyle_service.dart';
import '../../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alert_banner.dart';
import '../widgets/score_ring.dart';
import 'cognitive_test_screen.dart';
import 'lifestyle_checkin_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _cogService = CognitiveService();
  final _lifeService = LifestyleService();

  DashboardState? _state;
  String _userName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final profile = await ProfileService.getProfile();
    final latestCog = await _cogService.getLatestSession();
    final latestLife = await _lifeService.getLatestCheckin();
    final changeResult = await _cogService.getChangeResult();

    setState(() {
      _userName = profile != null ? '${profile.age}세' : '';
      _state = DashboardState(
        cognitiveScore: latestCog?.compositeScore,
        lifestyleScore: latestLife?.lifestyleScore,
        changeResult: changeResult,
        lastCognitiveDate: latestCog?.testedAt,
        lastLifestyleDate: latestLife?.checkedAt,
      );
      _loading = false;
    });
  }

  Future<void> _goToCognitiveTest() async {
    final profile = await ProfileService.getProfile();
    if (!mounted || profile == null) return;
    final count = await _cogService.getSessionCount();
    if (!mounted) return;
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CognitiveTestScreen(
          userAge: profile.age,
          sessionCount: count,
        ),
      ),
    );
    if (refreshed == true) _loadData();
  }

  Future<void> _goToLifestyleCheckin() async {
    final profile = await ProfileService.getProfile();
    if (!mounted || profile == null) return;
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LifestyleCheckinScreen(profile: profile),
      ),
    );
    if (refreshed == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('뇌 건강 지킴이'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(_userName,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Alert banner
                    if (_state?.changeResult != null &&
                        (_state!.changeResult!.alert ||
                            _state!.changeResult!.recommendReset))
                      AlertBanner(result: _state!.changeResult!),

                    // Integrated score card
                    _buildIntegratedCard(),

                    const SizedBox(height: 12),

                    // Sub-scores row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _ScoreCard(
                              label: '인지 점수',
                              score: _state?.cognitiveScore,
                              icon: Icons.psychology_outlined,
                              lastDate: _state?.lastCognitiveDate,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ScoreCard(
                              label: '라이프스타일',
                              score: _state?.lifestyleScore,
                              icon: Icons.favorite_outline,
                              lastDate: _state?.lastLifestyleDate,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _ActionButton(
                            icon: Icons.psychology,
                            title: '인지 기능 테스트',
                            subtitle: '약 5분 소요 · 월 1회 권장',
                            color: const Color(0xFF2E7D5E),
                            onTap: _goToCognitiveTest,
                          ),
                          const SizedBox(height: 12),
                          _ActionButton(
                            icon: Icons.checklist_rounded,
                            title: '라이프스타일 체크인',
                            subtitle: '수면·운동·식습관 등 8가지 항목',
                            color: const Color(0xFF1565C0),
                            onTap: _goToLifestyleCheckin,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Disclaimer
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        '⚠️ 이 앱의 점수는 의학적 진단이 아닙니다. 이상이 느껴지면 전문의와 상담하세요.',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildIntegratedCard() {
    final score = _state?.integratedScore;
    final hasData = score != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: hasData
            ? LinearGradient(
                colors: [
                  AppTheme.scoreColor(score!).withOpacity(0.85),
                  AppTheme.scoreColor(score).withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [Colors.grey.shade300, Colors.grey.shade200]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasData ? AppTheme.scoreColor(score!) : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ScoreRing(
            score: score,
            label: '통합 점수',
            size: 130,
            strokeWidth: 9,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasData ? AppTheme.scoreTierLabel(score!) : '데이터 없음',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  hasData
                      ? _tierDescription(score!)
                      : '인지 테스트 또는\n라이프스타일 체크인을\n시작해 보세요.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 10),
                  Text(
                    '인지 ${(_state?.cognitiveScore ?? 0).toStringAsFixed(0)}점  '
                    '+ 라이프스타일 ${(_state?.lifestyleScore ?? 0).toStringAsFixed(0)}점',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _tierDescription(double score) {
    return lifestyleMessage(lifestyleTier(score));
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final String label;
  final double? score;
  final IconData icon;
  final DateTime? lastDate;

  const _ScoreCard({
    required this.label,
    required this.score,
    required this.icon,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final hasScore = score != null;
    final color = hasScore ? AppTheme.scoreColor(score!) : Colors.grey;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasScore ? score!.toStringAsFixed(1) : '--',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (hasScore)
              Text(
                AppTheme.scoreTierLabel(score!),
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500),
              ),
            if (lastDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _formatDate(lastDate!),
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} 측정';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
