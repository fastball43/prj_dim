import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/algorithms/animal_lexicon.dart';
import '../../core/algorithms/cognitive_scoring.dart';
import '../../services/cognitive_service.dart';
import '../widgets/t4_trail_canvas.dart';

// ─── Phase enum ───────────────────────────────────────────────────────────────

enum _Phase {
  loading,
  intro,
  t1Showing,
  t1Immediate,
  t2Verbal,
  t3Forward,
  t3Backward,
  t4PartA,
  t4PartB,
  t1Delayed,
  saving,
  results,
}

enum _DigitSubPhase { presenting, inputting, feedback }

// ─── Screen ───────────────────────────────────────────────────────────────────

class CognitiveTestScreen extends StatefulWidget {
  final int userAge;
  final int sessionCount;

  const CognitiveTestScreen({
    super.key,
    required this.userAge,
    required this.sessionCount,
  });

  @override
  State<CognitiveTestScreen> createState() => _CognitiveTestScreenState();
}

class _CognitiveTestScreenState extends State<CognitiveTestScreen> {
  final _service = CognitiveService();

  _Phase _phase = _Phase.intro;

  // ── T1 Word Recall ──
  late String _wordSet;
  late List<String> _wordList;
  late List<String> _recallOptions; // target + foils, shuffled
  int _wordShowIndex = 0;
  Timer? _wordTimer;
  final Set<String> _t1ImmediateSelected = {};
  final Set<String> _t1DelayedSelected = {};
  int _t1Immediate = 0;
  int _t1Delayed = 0;

  // ── T2 Verbal Fluency ──
  final _t2Controller = TextEditingController();
  Timer? _t2Timer;
  int _t2Countdown = 60;
  int _t2WordCount = 0;

  // ── T3 Digit Span ──
  bool _t3IsForward = true;
  int _t3SpanLength = 3;
  int _t3Attempt = 1; // 1 or 2
  int _t3ForwardSpan = 0;
  int _t3BackwardSpan = 0;
  List<int> _t3Sequence = [];
  int _t3DigitIndex = 0;
  int? _t3ShownDigit;
  Timer? _t3Timer;
  _DigitSubPhase _t3SubPhase = _DigitSubPhase.presenting;
  bool _t3LastCorrect = false;
  final _t3Controller = TextEditingController();

  // ── T4 Trail Making ──
  double _t4TimeA = 0;
  double _t4TimeB = 0;

  // ── Results ──
  double _resultComposite = 0;

  static const _foilsA = ['배', '버스', '바람', '책상', '색연필'];
  static const _foilsB = ['강', '달력', '풀', '별', '양말'];

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    _wordSet = wordSetForSession(widget.sessionCount + 1);
    _wordList = getWordSet(_wordSet);
    final foils = _wordSet == 'A' ? _foilsA : _foilsB;
    _recallOptions = [..._wordList, ...foils]..shuffle(Random());
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    _t2Timer?.cancel();
    _t3Timer?.cancel();
    _t2Controller.dispose();
    _t3Controller.dispose();
    super.dispose();
  }

  // ─── Phase transitions ────────────────────────────────────────────────────

  void _startT1Show() {
    _wordShowIndex = 0;
    setState(() => _phase = _Phase.t1Showing);
    _wordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_wordShowIndex < _wordList.length - 1) {
        setState(() => _wordShowIndex++);
      } else {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 600),
            () => mounted ? setState(() => _phase = _Phase.t1Immediate) : null);
      }
    });
  }

  void _submitT1Immediate() {
    _t1Immediate = recallCorrectCount(
        selected: _t1ImmediateSelected, targets: _wordList);
    setState(() => _phase = _Phase.t2Verbal);
    _startT2();
  }

  void _startT2() {
    _t2Countdown = 60;
    _t2Controller.clear();
    _t2Timer =
        Timer.periodic(const Duration(seconds: 1), (t) {
      if (_t2Countdown > 1) {
        setState(() => _t2Countdown--);
      } else {
        t.cancel();
        _submitT2();
      }
    });
  }

  void _submitT2() {
    _t2Timer?.cancel();
    _t2WordCount = countValidAnimalNames(_t2Controller.text);
    _startT3();
  }

  void _startT3() {
    _t3IsForward = true;
    _t3SpanLength = 3;
    _t3Attempt = 1;
    _t3ForwardSpan = 0;
    setState(() => _phase = _Phase.t3Forward);
    _showNextDigitSequence();
  }

  void _showNextDigitSequence() {
    _t3Sequence = _generateDigits(_t3SpanLength);
    _t3DigitIndex = 0;
    _t3ShownDigit = null;
    _t3Controller.clear();
    _t3SubPhase = _DigitSubPhase.presenting;

    _t3Timer?.cancel();
    // Brief pause before showing first digit
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _t3Timer =
          Timer.periodic(const Duration(milliseconds: 800), (t) {
        if (_t3DigitIndex < _t3Sequence.length) {
          setState(() {
            _t3ShownDigit = _t3Sequence[_t3DigitIndex];
            _t3DigitIndex++;
          });
        } else {
          t.cancel();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _t3ShownDigit = null;
                _t3SubPhase = _DigitSubPhase.inputting;
              });
            }
          });
        }
      });
    });
  }

  void _submitT3Answer() {
    final input =
        _t3Controller.text.trim().replaceAll(RegExp(r'\s+'), '');
    final expected = _t3IsForward
        ? _t3Sequence.join()
        : _t3Sequence.reversed.join();
    _t3LastCorrect = input == expected;
    _t3SubPhase = _DigitSubPhase.feedback;
    setState(() {});

    Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_t3LastCorrect) {
        if (_t3IsForward) {
          _t3ForwardSpan = _t3SpanLength;
        } else {
          _t3BackwardSpan = _t3SpanLength;
        }
        _t3SpanLength++;
        _t3Attempt = 1;
        final maxSpan = _t3IsForward ? 7 : 6;
        if (_t3SpanLength > maxSpan) {
          _endT3Phase();
        } else {
          _showNextDigitSequence();
        }
      } else if (_t3Attempt < 2) {
        _t3Attempt = 2;
        _showNextDigitSequence();
      } else {
        _endT3Phase();
      }
    });
  }

  void _endT3Phase() {
    if (_t3IsForward) {
      _t3IsForward = false;
      _t3SpanLength = 2;
      _t3Attempt = 1;
      _t3BackwardSpan = 0;
      setState(() => _phase = _Phase.t3Backward);
      _showNextDigitSequence();
    } else {
      setState(() => _phase = _Phase.t4PartA);
    }
  }

  void _onT4AComplete(double elapsed) {
    _t4TimeA = elapsed;
    setState(() => _phase = _Phase.t4PartB);
  }

  void _onT4BComplete(double elapsed) {
    _t4TimeB = elapsed;
    setState(() => _phase = _Phase.t1Delayed);
  }

  void _submitT1Delayed() {
    _t1Delayed = recallCorrectCount(
        selected: _t1DelayedSelected, targets: _wordList);
    _saveResults();
  }

  Future<void> _saveResults() async {
    setState(() => _phase = _Phase.saving);
    final result = await _service.saveSession(
      t1Immediate: _t1Immediate,
      t1Delayed: _t1Delayed,
      t2WordCount: _t2WordCount,
      userAge: widget.userAge,
      t3ForwardSpan: _t3ForwardSpan,
      t3BackwardSpan: _t3BackwardSpan,
      t4TimeA: _t4TimeA > 0 ? _t4TimeA : 30,
      t4TimeB: _t4TimeB > 0 ? _t4TimeB : 60,
      wordSet: _wordSet,
    );
    _resultComposite = result.composite;
    setState(() => _phase = _Phase.results);
  }

  // ─── Utilities ────────────────────────────────────────────────────────────

  List<int> _generateDigits(int length) {
    final rand = Random();
    final seq = <int>[];
    while (seq.length < length) {
      final d = rand.nextInt(9) + 1; // 1-9, no leading zero confusion
      if (seq.isEmpty || d != seq.last) seq.add(d);
    }
    return seq;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: _phase == _Phase.intro ||
            _phase == _Phase.results,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  String _appBarTitle() {
    switch (_phase) {
      case _Phase.t1Showing:
      case _Phase.t1Immediate:
      case _Phase.t1Delayed:
        return '1. 단어 기억';
      case _Phase.t2Verbal:
        return '2. 동물 이름 떠올리기';
      case _Phase.t3Forward:
      case _Phase.t3Backward:
        return '3. 숫자 따라하기';
      case _Phase.t4PartA:
      case _Phase.t4PartB:
        return '4. 연결 잇기';
      case _Phase.results:
        return '결과';
      default:
        return '인지 기능 테스트';
    }
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.loading:
        return const Center(child: CircularProgressIndicator());
      case _Phase.intro:
        return _buildIntro();
      case _Phase.t1Showing:
        return _buildT1Show();
      case _Phase.t1Immediate:
        return _buildT1Recall(delayed: false);
      case _Phase.t2Verbal:
        return _buildT2();
      case _Phase.t3Forward:
      case _Phase.t3Backward:
        return _buildT3();
      case _Phase.t4PartA:
        return _buildT4(isPartA: true);
      case _Phase.t4PartB:
        return _buildT4(isPartA: false);
      case _Phase.t1Delayed:
        return _buildT1Recall(delayed: true);
      case _Phase.saving:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('결과 저장 중...'),
            ],
          ),
        );
      case _Phase.results:
        return _buildResults();
    }
  }

  // ── Intro ─────────────────────────────────────────────────────────────────

  Widget _buildIntro() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('인지 기능 테스트',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('4가지 테스트로 기억력, 언어, 주의력, 처리 속도를 측정합니다.',
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 28),
          _introItem('1', '단어 기억', '5개 단어를 기억 후 즉시·지연 회상', Colors.teal),
          _introItem('2', '동물 이름', '60초 안에 동물 이름을 최대한 많이', Colors.blue),
          _introItem('3', '숫자 따라하기', '숫자를 순서대로·역순으로 입력', Colors.indigo),
          _introItem('4', '연결 잇기', '화면 숫자를 순서대로 탭', Colors.purple),
          const Spacer(),
          const Text('⚠️ 이 결과는 의학적 진단이 아닙니다',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _startT1Show,
            child: const Text('시작하기'),
          ),
        ],
      ),
    );
  }

  Widget _introItem(
      String num, String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: Text(num,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              Text(desc,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  // ── T1 Show ───────────────────────────────────────────────────────────────

  Widget _buildT1Show() {
    final word = _wordList[_wordShowIndex];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('단어를 잘 기억해 주세요',
              style: TextStyle(fontSize: 17, color: Colors.grey)),
          const SizedBox(height: 40),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              word,
              key: ValueKey(word),
              style: const TextStyle(
                  fontSize: 58, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 40),
          Text('${_wordShowIndex + 1} / ${_wordList.length}',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── T1 Recall ─────────────────────────────────────────────────────────────

  Widget _buildT1Recall({required bool delayed}) {
    final selected =
        delayed ? _t1DelayedSelected : _t1ImmediateSelected;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            delayed ? '아까 보신 단어를 모두 선택해 주세요' : '방금 보신 단어를 모두 선택해 주세요',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text('기억나는 것만 선택하세요 (보지 않은 단어를 고르면 감점돼요)',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _recallOptions.map((word) {
              final sel = selected.contains(word);
              return FilterChip(
                label: Text(word,
                    style: const TextStyle(fontSize: 16)),
                selected: sel,
                onSelected: (v) => setState(
                    () => v ? selected.add(word) : selected.remove(word)),
                selectedColor:
                    Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor:
                    Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: delayed ? _submitT1Delayed : _submitT1Immediate,
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // ── T2 Verbal Fluency ─────────────────────────────────────────────────────

  Widget _buildT2() {
    final urgent = _t2Countdown <= 10;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('동물 이름 떠올리기',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: urgent
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$_t2Countdown초',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: urgent
                          ? Colors.red.shade800
                          : Colors.green.shade800,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('쉼표 또는 줄바꿈으로 구분해 입력해 주세요 (같은 동물은 한 번만 세요)',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _t2Controller,
              autofocus: true,
              maxLines: null,
              expands: true,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: '예) 개, 고양이, 말, 토끼...',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _submitT2,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
            child: const Text('완료 (시간이 남아도 괜찮아요)'),
          ),
        ],
      ),
    );
  }

  // ── T3 Digit Span ─────────────────────────────────────────────────────────

  Widget _buildT3() {
    final isForward = _phase == _Phase.t3Forward;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isForward ? '숫자 따라하기 — 순서대로' : '숫자 따라하기 — 역순으로',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_t3SpanLength}자리  ${_t3Attempt}회 / 2회 시도',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildT3SubPhase(isForward)),
        ],
      ),
    );
  }

  Widget _buildT3SubPhase(bool isForward) {
    switch (_t3SubPhase) {
      case _DigitSubPhase.presenting:
        return _buildDigitPresenting();
      case _DigitSubPhase.inputting:
        return _buildDigitInputting(isForward);
      case _DigitSubPhase.feedback:
        return _buildDigitFeedback();
    }
  }

  Widget _buildDigitPresenting() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('숫자를 잘 기억해 주세요',
            style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 48),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: _t3ShownDigit == null
              ? const SizedBox(height: 110)
              : Text(
                  '$_t3ShownDigit',
                  key: ValueKey('$_t3DigitIndex-$_t3ShownDigit'),
                  style: const TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4),
                ),
        ),
      ],
    );
  }

  Widget _buildDigitInputting(bool isForward) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isForward ? '방금 본 숫자를 순서대로 입력해 주세요' : '방금 본 숫자를 거꾸로 입력해 주세요',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _t3Controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style:
              const TextStyle(fontSize: 32, letterSpacing: 10),
          decoration: const InputDecoration(
            hintText: '숫자 입력',
            helperText: '공백 없이 연속으로 입력 후 확인',
          ),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _submitT3Answer,
          child: const Text('확인'),
        ),
      ],
    );
  }

  Widget _buildDigitFeedback() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _t3LastCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 90,
            color: _t3LastCorrect ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _t3LastCorrect ? '정답입니다!' : '틀렸습니다',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _t3LastCorrect ? Colors.green : Colors.red,
            ),
          ),
          if (!_t3LastCorrect && _t3Attempt < 2)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('한 번 더 시도할 수 있습니다',
                  style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  // ── T4 Trail Making ───────────────────────────────────────────────────────

  Widget _buildT4({required bool isPartA}) {
    final labels = isPartA
        ? ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10']
        : ['1', '가', '2', '나', '3', '다', '4', '라', '5', '마'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPartA ? '연결 잇기 — 1단계: 숫자 순서' : '연결 잇기 — 2단계: 숫자·한글 교대',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold),
          ),
          Text(
            isPartA ? '1 → 2 → 3 → ... → 10' : '1 → 가 → 2 → 나 → ... → 5 → 마',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: T4TrailCanvas(
              key: ValueKey(isPartA ? 'A' : 'B'),
              labels: labels,
              onComplete:
                  isPartA ? _onT4AComplete : _onT4BComplete,
            ),
          ),
        ],
      ),
    );
  }

  // ── Results ───────────────────────────────────────────────────────────────

  Widget _buildResults() {
    final t1s = scoreT1(correctDelayed: _t1Delayed);
    final t2s = scoreT2(wordCount: _t2WordCount, age: widget.userAge);
    final t3s = scoreT3(
        forwardSpan: _t3ForwardSpan, backwardSpan: _t3BackwardSpan);
    final t4s = scoreT4(
        timeA: _t4TimeA > 0 ? _t4TimeA : 30,
        timeB: _t4TimeB > 0 ? _t4TimeB : 60);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('테스트 완료!',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('⚠️ 이 결과는 의학적 진단이 아닙니다',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 24),
          _resultCard('종합 인지 점수', _resultComposite, primary: true),
          const SizedBox(height: 12),
          _resultCard('기억력 (단어 회상)', t1s),
          const SizedBox(height: 8),
          _resultCard('언어 유창성 (동물 이름)', t2s),
          const SizedBox(height: 8),
          _resultCard('주의력 (숫자 폭)', t3s),
          const SizedBox(height: 8),
          _resultCard('처리 속도 (연결 잇기)', t4s),
          const SizedBox(height: 8),
          // Sub-details
          _detailRow('즉시 회상', '$_t1Immediate / 5개'),
          _detailRow('지연 회상', '$_t1Delayed / 5개'),
          _detailRow('동물 이름 수', '$_t2WordCount개'),
          _detailRow('Forward span', '${_t3ForwardSpan}자리'),
          _detailRow('Backward span', '${_t3BackwardSpan}자리'),
          if (_t4TimeA > 0) _detailRow('Trail A', '${_t4TimeA.toStringAsFixed(1)}초'),
          if (_t4TimeB > 0) _detailRow('Trail B', '${_t4TimeB.toStringAsFixed(1)}초'),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('대시보드로 돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _resultCard(String title, double score,
      {bool primary = false}) {
    final color = score >= 75
        ? Colors.green.shade700
        : score >= 50
            ? Colors.orange.shade700
            : Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primary ? color.withOpacity(0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: primary ? color.withOpacity(0.4) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: primary ? 16 : 14,
                      fontWeight: primary
                          ? FontWeight.bold
                          : FontWeight.normal))),
          Text(
            '${score.toStringAsFixed(1)}점',
            style: TextStyle(
                fontSize: primary ? 22 : 18,
                fontWeight: FontWeight.bold,
                color: color),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label  ',
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
