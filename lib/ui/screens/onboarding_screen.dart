import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/database/profile_dao.dart';
import '../../services/profile_service.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form values
  final _birthYearController = TextEditingController();
  int _educationYears = 12; // 기본: 고졸
  bool _familyHistory = false;
  bool _hasDiabetes = false;

  bool get _canNext {
    if (_currentPage == 0) {
      final y = int.tryParse(_birthYearController.text);
      return y != null && y >= 1930 && y <= 2010;
    }
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _birthYearController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    final birthYear = int.parse(_birthYearController.text);
    final now = DateTime.now();
    final profile = UserProfile(
      birthYear: birthYear,
      educationYears: _educationYears,
      familyHistory: _familyHistory,
      hasDiabetes: _hasDiabetes,
      createdAt: now,
      updatedAt: now,
    );
    await ProfileService.saveProfile(profile);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _currentPage
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return _StepShell(
      step: 1,
      title: '출생 연도를 알려주세요',
      subtitle: '연령에 맞는 기준값으로 점수를 보정합니다',
      child: TextField(
        controller: _birthYearController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        autofocus: true,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          hintText: '예) 1960',
          helperText: '1930 ~ 2010 사이로 입력해 주세요',
          helperStyle: TextStyle(fontSize: 14),
        ),
        onChanged: (_) => setState(() {}),
      ),
      canNext: _canNext,
      onNext: _next,
    );
  }

  Widget _buildStep2() {
    const options = [
      (label: '초등학교 졸업', years: 6),
      (label: '중학교 졸업', years: 9),
      (label: '고등학교 졸업', years: 12),
      (label: '대학교 졸업 이상', years: 16),
    ];
    return _StepShell(
      step: 2,
      title: '최종 학력을 선택해 주세요',
      subtitle: '교육 연수는 인지 예비력과 관련이 있습니다',
      child: Column(
        children: options
            .map((opt) => RadioListTile<int>(
                  title: Text(opt.label, style: const TextStyle(fontSize: 16)),
                  value: opt.years,
                  groupValue: _educationYears,
                  onChanged: (v) =>
                      setState(() => _educationYears = v!),
                  activeColor:
                      Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ))
            .toList(),
      ),
      canNext: true,
      onNext: _next,
    );
  }

  Widget _buildStep3() {
    return _StepShell(
      step: 3,
      title: '가족 중 치매를 진단받은 분이 계신가요?',
      subtitle: '부모님 또는 형제자매(1촌) 기준입니다',
      child: Column(
        children: [
          _BigRadioTile(
            label: '없습니다',
            selected: !_familyHistory,
            onTap: () => setState(() => _familyHistory = false),
          ),
          const SizedBox(height: 12),
          _BigRadioTile(
            label: '있습니다',
            selected: _familyHistory,
            onTap: () => setState(() => _familyHistory = true),
          ),
        ],
      ),
      canNext: true,
      onNext: _next,
    );
  }

  Widget _buildStep4() {
    return _StepShell(
      step: 4,
      title: '당뇨 진단을 받으신 적이 있나요?',
      subtitle: '혈관 건강 점수 계산에 반영됩니다',
      child: Column(
        children: [
          _BigRadioTile(
            label: '없습니다',
            selected: !_hasDiabetes,
            onTap: () => setState(() => _hasDiabetes = false),
          ),
          const SizedBox(height: 12),
          _BigRadioTile(
            label: '있습니다 (당뇨 진단)',
            selected: _hasDiabetes,
            onTap: () => setState(() => _hasDiabetes = true),
          ),
        ],
      ),
      canNext: true,
      onNext: _next,
      nextLabel: '시작하기',
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _StepShell extends StatelessWidget {
  final int step;
  final String title;
  final String subtitle;
  final Widget child;
  final bool canNext;
  final VoidCallback onNext;
  final String nextLabel;

  const _StepShell({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.canNext,
    required this.onNext,
    this.nextLabel = '다음',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$step / 4', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          Text(title,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 32),
          child,
          const Spacer(),
          ElevatedButton(
            onPressed: canNext ? onNext : null,
            child: Text(nextLabel),
          ),
        ],
      ),
    );
  }
}

class _BigRadioTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BigRadioTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? color : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
