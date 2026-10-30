import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../services/ai_mcq_service.dart';

class StudentTakeExamScreen extends StatefulWidget {
  final String examId;
  final String examTitle;
  final int durationMinutes;

  const StudentTakeExamScreen({
    super.key,
    required this.examId,
    required this.examTitle,
    this.durationMinutes = 30,
  });

  @override
  State<StudentTakeExamScreen> createState() => _StudentTakeExamScreenState();
}

class _StudentTakeExamScreenState extends State<StudentTakeExamScreen> {
  List<QueryDocumentSnapshot> _questions = [];
  final Map<int, int> _answers = {};
  final Set<int> _locked = {};
  final Set<int> _revealed = {};

  bool _loading = true;
  bool _submitted = false;
  int _secondsLeft = 0;
  Timer? _timer;

  int _score = 0;
  List<_ResultItem> _results = [];
  String _aiTips = '';
  bool _tipsLoading = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.durationMinutes * 60;
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection('exams')
        .doc(widget.examId)
        .collection('questions')
        .orderBy('order')
        .get();

    setState(() {
      _questions = snap.docs;
      _loading = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        if (!_submitted) _submit();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  String get _timeLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onSelect(int qIndex, int optionIndex, int correctIndex) {
    if (_locked.contains(qIndex) || _submitted) return;
    setState(() {
      _answers[qIndex] = optionIndex;
      _locked.add(qIndex);
      if (optionIndex != correctIndex) {
        _revealed.add(qIndex);
      }
    });
  }

  Future<void> _submit() async {
    if (_submitted) return;
    _timer?.cancel();

    var score = 0;
    final items = <_ResultItem>[];

    for (var i = 0; i < _questions.length; i++) {
      final d = _questions[i].data() as Map<String, dynamic>;
      final opts = List<String>.from(d['options'] ?? []);
      final correct = d['correctIndex'] as int? ?? 0;
      final chosen = _answers[i];
      final ok = chosen != null && chosen == correct;
      if (ok) score++;

      items.add(
        _ResultItem(
          index: i + 1,
          text: d['text']?.toString() ?? '',
          options: opts,
          correctIndex: correct,
          selectedIndex: chosen,
          explanation: d['explanation']?.toString() ?? '',
          isCorrect: ok,
        ),
      );
    }

    setState(() {
      _score = score;
      _results = items;
      _submitted = true;
      _tipsLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('exam_attempts').add({
        'examId': widget.examId,
        'examTitle': widget.examTitle,
        'studentId': uid,
        'score': score,
        'total': _questions.length,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    final tips = await _generateTeacherTips(items, score);
    if (!mounted) return;
    setState(() {
      _aiTips = tips;
      _tipsLoading = false;
    });
  }

  /// AI writes tips as the teacher would
  Future<String> _generateTeacherTips(
    List<_ResultItem> items,
    int score,
  ) async {
    if (!AiMcqService.isConfigured) {
      return _fallbackTip(score, items.length);
    }

    final wrong = items.where((e) => !e.isCorrect).toList();
    final summary = wrong.isEmpty
        ? 'Student got all correct.'
        : wrong
              .take(12)
              .map((w) {
                final sel = w.selectedIndex;
                final selText = sel != null && sel < w.options.length
                    ? w.options[sel]
                    : 'skipped';
                final cor = w.correctIndex < w.options.length
                    ? w.options[w.correctIndex]
                    : '';
                return 'Q${w.index}: ${w.text}\n'
                    'Student chose: $selText\n'
                    'Correct: $cor\n'
                    'Note: ${w.explanation}';
              })
              .join('\n\n');

    final prompt =
        '''
You are a caring teacher at BSGD Academy (Bangladesh HSC/SSC coaching).
A student just finished the MCQ exam "${widget.examTitle}".
Score: $score out of ${items.length}.

Based on the wrong answers below, write short personalized study tips in Bangla (or Bangla mixed with simple English terms if needed).
Speak as the teacher: encouraging, clear, practical.
Include:
1) Overall comment on performance
2) Which topics to revise
3) 3–5 concrete tips
4) Motivation to try again

Keep under 180 words. No markdown fences.

WRONG ANSWERS:
$summary
''';

    try {
      const models = [
        'gemini-2.5-flash',
        'gemini-flash-latest',
        'gemini-2.5-flash-lite',
        'gemini-3.5-flash',
      ];
      final apiKey = AiMcqService.apiKey;

      for (final model in models) {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/'
          '$model:generateContent?key=$apiKey',
        );
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                ],
              },
            ],
            'generationConfig': {'temperature': 0.5},
          }),
        );
        if (res.statusCode != 200) continue;
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text']
                ?.toString()
                .trim() ??
            '';
        if (text.isNotEmpty) return text;
      }
    } catch (_) {}

    return _fallbackTip(score, items.length);
  }

  String _fallbackTip(int score, int total) {
    final pct = total == 0 ? 0 : (score * 100 / total).round();
    if (pct >= 80) {
      return 'দারুণ করেছেন! ভুলগুলো আবার দেখে নিন এবং একই ধরনের প্রশ্ন অনুশীলন করুন। নিয়মিত রিভিশন চালিয়ে যান।';
    }
    if (pct >= 50) {
      return 'ভালো চেষ্টা হয়েছে। ভুল উত্তরগুলোর ব্যাখ্যা পড়ুন, সংশ্লিষ্ট অধ্যায় ঝালিয়ে আবার পরীক্ষা দিন।';
    }
    return 'চিন্তা করবেন না। প্রতিটি ভুলের নিচে সঠিক উত্তর ও ব্যাখ্যা দেখুন, অধ্যায় রিভিশন দিয়ে আবার চেষ্টা করুন। শিক্ষক হিসেবে আমরা আপনার পাশে আছি।';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.examTitle)),
        body: const Center(child: Text('No questions in this exam.')),
      );
    }

    if (_submitted) {
      return _ResultView(
        examTitle: widget.examTitle,
        score: _score,
        total: _questions.length,
        results: _results,
        aiTips: _aiTips,
        tipsLoading: _tipsLoading,
        onDone: () => Navigator.pop(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live MCQ Assessment'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _secondsLeft < 60
                  ? Colors.red.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: _secondsLeft < 60 ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  _timeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _secondsLeft < 60
                        ? Colors.red
                        : Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _questions.length,
        itemBuilder: (context, i) {
          final d = _questions[i].data() as Map<String, dynamic>;
          final opts = List<String>.from(d['options'] ?? []);
          final text = d['text']?.toString() ?? '';
          final correct = d['correctIndex'] as int? ?? 0;
          final explanation = d['explanation']?.toString() ?? '';
          final locked = _locked.contains(i);
          final selected = _answers[i];
          final showAnswer = _revealed.contains(i);

          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // No English "Q12:" — only number + text
                  Text(
                    '${i + 1}. $text',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(opts.length, (oi) {
                    Color? fill;
                    Color? borderC;
                    if (locked) {
                      if (oi == correct && showAnswer) {
                        fill = Colors.green.withOpacity(0.12);
                        borderC = Colors.green;
                      } else if (oi == selected && selected != correct) {
                        fill = Colors.red.withOpacity(0.1);
                        borderC = Colors.red;
                      }
                    } else if (selected == oi) {
                      fill = AppTheme.royalBlue.withOpacity(0.08);
                      borderC = AppTheme.royalBlue;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                        color: fill ?? Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: locked
                              ? null
                              : () => _onSelect(i, oi, correct),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: borderC ?? Colors.grey.shade300,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected == oi
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 20,
                                  color: selected == oi
                                      ? AppTheme.royalBlue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(opts[oi])),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  if (showAnswer) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'সঠিক উত্তর: ${String.fromCharCode(65 + correct)}. '
                            '${correct < opts.length ? opts[correct] : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.green.shade800,
                            ),
                          ),
                          if (explanation.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              explanation,
                              style: const TextStyle(height: 1.4, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () async {
              final unanswered = _questions.length - _answers.length;
              if (unanswered > 0) {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Submit exam?'),
                    content: Text(
                      'You left $unanswered question(s) unanswered.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Review'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Submit'),
                      ),
                    ],
                  ),
                );
                if (ok != true) return;
              }
              await _submit();
            },
            child: const Text(
              'Submit exam',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultItem {
  final int index;
  final String text;
  final List<String> options;
  final int correctIndex;
  final int? selectedIndex;
  final String explanation;
  final bool isCorrect;

  _ResultItem({
    required this.index,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.selectedIndex,
    required this.explanation,
    required this.isCorrect,
  });
}

class _ResultView extends StatelessWidget {
  final String examTitle;
  final int score;
  final int total;
  final List<_ResultItem> results;
  final String aiTips;
  final bool tipsLoading;
  final VoidCallback onDone;

  const _ResultView({
    required this.examTitle,
    required this.score,
    required this.total,
    required this.results,
    required this.aiTips,
    required this.tipsLoading,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (score * 100 / total).round();

    return Scaffold(
      appBar: AppBar(title: const Text('ফলাফল')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    examTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$score / $total',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: AppTheme.academicGold.withOpacity(0.12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school, color: AppTheme.academicGold),
                      SizedBox(width: 8),
                      Text(
                        'শিক্ষকের টিপস',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (tipsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('শিক্ষক টিপস তৈরি করছেন…'),
                        ],
                      ),
                    )
                  else
                    Text(
                      aiTips.isEmpty
                          ? 'টিপস পাওয়া যায়নি। ভুলগুলো নিজে রিভিউ করুন।'
                          : aiTips,
                      style: const TextStyle(height: 1.45, fontSize: 14),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'পর্যালোচনা',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ...results.map((r) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                leading: Icon(
                  r.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: r.isCorrect ? Colors.green : Colors.red,
                ),
                title: Text(
                  '${r.index}. ${r.text}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  r.isCorrect ? 'সঠিক' : 'ভুল',
                  style: TextStyle(
                    color: r.isCorrect ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(r.options.length, (oi) {
                          final isRight = oi == r.correctIndex;
                          final isPick = oi == r.selectedIndex;
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isRight
                                  ? Colors.green.withOpacity(0.12)
                                  : isPick
                                  ? Colors.red.withOpacity(0.1)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isRight
                                    ? Colors.green
                                    : isPick
                                    ? Colors.red
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              '${String.fromCharCode(65 + oi)}. ${r.options[oi]}'
                              '${isRight ? '  ✓' : ''}'
                              '${isPick && !isRight ? '  (আপনার উত্তর)' : ''}',
                            ),
                          );
                        }),
                        if (r.explanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'টিপস: ${r.explanation}',
                            style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: onDone,
            child: const Text('ফিরে যান'),
          ),
        ],
      ),
    );
  }
}
