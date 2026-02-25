import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/algorithms/lifestyle_scoring.dart';
import '../../core/database/profile_dao.dart';
import '../../services/lifestyle_service.dart';
import '../theme/app_theme.dart';

class LifestyleCheckinScreen extends StatefulWidget {
  final UserProfile profile;

  const LifestyleCheckinScreen({super.key, required this.profile});

  @override
  State<LifestyleCheckinScreen> createState() =>
      _LifestyleCheckinScreenState();
}

class _LifestyleCheckinScreenState
    extends State<LifestyleCheckinScreen> {
  final _service = LifestyleService();
  bool _saving = false;

  // ── 1. 수면 ──
  double _sleepHours = 7.0;
  int _sleepQuality = 3;

  // ── 2. 신체 활동 ──
  int _exerciseDays = 0;
  int _exerciseMinutes = 0;

  // ── 3. 식습관 (MIND diet) ──
  int _dietChecked = 0;

  // ── 4. 사회 활동 ──
  int _socialFreq = 2; // 0-4

  // ── 5. 정신 자극 ──
  int _stimFreq = 2; // 0-4

  // ── 6. 혈관 건강 ──
  final _bpController = TextEditingController();

  // ── 7. 청각 ──
  int _hearing = 0; // 0-3

  // ── 8. 음주/흡연 ──
  int _alcoholFreq = 0; // 0-3
  bool _isSmoker = false;

  @override
  void dispose() {
    _bpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final bp = int.tryParse(_bpController.text.trim());
    final input = LifestyleInput(
      sleepHours: _sleepHours,
      sleepQuality: _sleepQuality,
      exerciseDays: _exerciseDays,
      exerciseMinutes: _exerciseMinutes,
      dietCheckedItems: _dietChecked,
      socialFreqCode: _socialFreq,
      cognitiveStimFreqCode: _stimFreq,
      systolicBp: bp,
      hasDiabetes: widget.profile.hasDiabetes,
      hearingDifficulty: _hearing,
      alcoholFreq: _alcoholFreq,
      isSmoker: _isSmoker,
    );

    final score =
        await _service.saveCheckin(input: input, profile: widget.profile);

    if (!mounted) return;
    setState(() => _saving = false);
    _showResult(score);
  }

  void _showResult(double score) {
    final color = AppTheme.scoreColor(score);
    final tier = AppTheme.scoreTierLabel(score);
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            Text(tier,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 12),
            Text(lifestyleMessage(lifestyleTier(score)),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 8),
            const Text('⚠️ 이 결과는 의학적 진단이 아닙니다',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // close sheet
                Navigator.of(context).pop(true); // back to dashboard
              },
              child: const Text('대시보드로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('라이프스타일 체크인'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _saving
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('저장 중...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  _buildSleepSection(),
                  _buildDivider(),
                  _buildExerciseSection(),
                  _buildDivider(),
                  _buildDietSection(),
                  _buildDivider(),
                  _buildFreqSection(
                    title: '사회 활동',
                    subtitle: '가족·친구와의 대화, 모임 등',
                    icon: Icons.people_outline,
                    value: _socialFreq,
                    onChanged: (v) => setState(() => _socialFreq = v),
                  ),
                  _buildDivider(),
                  _buildFreqSection(
                    title: '정신 자극',
                    subtitle: '독서, 퍼즐, 새로운 학습 등',
                    icon: Icons.menu_book_outlined,
                    value: _stimFreq,
                    onChanged: (v) => setState(() => _stimFreq = v),
                  ),
                  _buildDivider(),
                  _buildVascularSection(),
                  _buildDivider(),
                  _buildHearingSection(),
                  _buildDivider(),
                  _buildSubstanceSection(),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('저장하기'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDivider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1),
      );

  // ─── Section builders ────────────────────────────────────────────────────

  Widget _buildSleepSection() {
    return _Section(
      icon: Icons.bedtime_outlined,
      title: '수면',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('평균 수면 시간'),
              Text('${_sleepHours.toStringAsFixed(1)}시간',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _sleepHours,
            min: 3,
            max: 12,
            divisions: 18,
            label: '${_sleepHours.toStringAsFixed(1)}h',
            onChanged: (v) => setState(() => _sleepHours = v),
          ),
          const SizedBox(height: 8),
          const Text('수면의 질 (1=매우 나쁨, 5=매우 좋음)',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              5,
              (i) {
                final val = i + 1;
                return GestureDetector(
                  onTap: () => setState(() => _sleepQuality = val),
                  child: Icon(
                    _sleepQuality >= val ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSection() {
    const minuteOptions = [0, 15, 30, 45, 60];
    return _Section(
      icon: Icons.directions_run_outlined,
      title: '신체 활동',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('주당 운동 일수'),
              Text('$_exerciseDays일',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _exerciseDays.toDouble(),
            min: 0,
            max: 7,
            divisions: 7,
            label: '$_exerciseDays일',
            onChanged: (v) =>
                setState(() => _exerciseDays = v.round()),
          ),
          const SizedBox(height: 8),
          const Text('1회 평균 운동 시간',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: minuteOptions.map((min) {
              final selected = _exerciseMinutes == min;
              return ChoiceChip(
                label: Text(min == 0 ? '안 함' : '$min분'),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _exerciseMinutes = min),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDietSection() {
    const items = [
      '잎채소 (주 6회+)',
      '견과류 (주 5회+)',
      '베리류 (주 2회+)',
      '콩류 (주 4회+)',
      '통곡물 (매일)',
      '생선 (주 1회+)',
      '가금류 (주 2회+)',
      '올리브오일 (주 사용)',
      '와인 소량 (선택)',
      '패스트푸드 줄이기',
    ];

    return _Section(
      icon: Icons.restaurant_outlined,
      title: 'MIND 식단 (${'$_dietChecked'}/10)',
      child: Column(
        children: items.asMap().entries.map((e) {
          final idx = e.key;
          final label = e.value;
          final checked = idx < _dietChecked;
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title:
                Text(label, style: const TextStyle(fontSize: 14)),
            value: checked,
            onChanged: (v) {
              if (v == true && idx == _dietChecked) {
                setState(() => _dietChecked++);
              } else if (v == false && idx == _dietChecked - 1) {
                setState(() => _dietChecked--);
              } else {
                // Allow direct toggle — compute new count
                setState(() => _dietChecked =
                    v! ? idx + 1 : idx);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFreqSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    const labels = ['거의 없음', '주 1회', '주 2-3회', '주 4-6회', '매일'];
    return _Section(
      icon: icon,
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labels[value],
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 4,
            divisions: 4,
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('거의 없음',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              Text('매일',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVascularSection() {
    return _Section(
      icon: Icons.favorite_border,
      title: '혈관 건강',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('수축기 혈압 (선택 — 미입력 시 중간값 적용)',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: _bpController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '예) 120',
              suffixText: 'mmHg',
            ),
          ),
          if (widget.profile.hasDiabetes)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.orange),
                  SizedBox(width: 6),
                  Text('당뇨 정보가 반영됩니다',
                      style: TextStyle(
                          fontSize: 13, color: Colors.orange)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHearingSection() {
    const options = ['어려움 없음', '가끔 어려움', '자주 어려움', '심각 (보청기 미사용)'];
    return _Section(
      icon: Icons.hearing_outlined,
      title: '청각',
      child: Column(
        children: options.asMap().entries.map((e) {
          return RadioListTile<int>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(e.value,
                style: const TextStyle(fontSize: 14)),
            value: e.key,
            groupValue: _hearing,
            onChanged: (v) => setState(() => _hearing = v!),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubstanceSection() {
    const alcoholOptions = ['안 마심', '월 1-3회', '주 1-2회', '주 3회 이상'];
    return _Section(
      icon: Icons.no_drinks_outlined,
      title: '음주 / 흡연',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('음주 빈도',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: alcoholOptions.asMap().entries.map((e) {
              return ChoiceChip(
                label: Text(e.value,
                    style: const TextStyle(fontSize: 13)),
                selected: _alcoholFreq == e.key,
                onSelected: (_) =>
                    setState(() => _alcoholFreq = e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('현재 흡연 중'),
            value: _isSmoker,
            onChanged: (v) => setState(() => _isSmoker = v),
          ),
        ],
      ),
    );
  }
}

// ─── Section wrapper widget ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 28),
              child: Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
            ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
