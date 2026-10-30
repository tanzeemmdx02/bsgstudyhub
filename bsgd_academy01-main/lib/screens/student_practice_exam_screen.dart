import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const _bn = TextStyle(
  fontFamily: 'Noto Sans Bengali',
  fontFamilyFallback: ['Hind Siliguri', 'Kalpurush', 'Arial'],
  height: 1.5,
);

String cleanQuestionText(String raw) {
  return raw
      .replaceFirst(RegExp(r'^\s*(?:Q\s*)?\d+[.)|:\-]\s*'), '')
      .replaceFirst(RegExp(r'^\s*[০-৯0-9]+[.)|:\-]\s*'), '')
      .trim();
}

class StudentPracticeExamScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const StudentPracticeExamScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<StudentPracticeExamScreen> createState() =>
      _StudentPracticeExamScreenState();
}

class _StudentPracticeExamScreenState extends State<StudentPracticeExamScreen> {
  /// Index into **questions only** (passages excluded from count)
  int _qIndex = 0;
  int? _selected;
  bool _revealed = false;
  int _score = 0;

  List<QueryDocumentSnapshot> _questionDocs(List<QueryDocumentSnapshot> all) {
    return all.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      return (d['type']?.toString() ?? 'question') != 'passage';
    }).toList();
  }

  /// Passage immediately before this question in full ordered list (if any)
  String? _passageFor(
    List<QueryDocumentSnapshot> all,
    QueryDocumentSnapshot qDoc,
  ) {
    final idx = all.indexWhere((d) => d.id == qDoc.id);
    if (idx <= 0) return null;
    for (var i = idx - 1; i >= 0; i--) {
      final d = all[i].data() as Map<String, dynamic>;
      final type = d['type']?.toString() ?? 'question';
      if (type == 'passage') {
        return cleanQuestionText(d['text']?.toString() ?? '');
      }
      // hit another question → no passage in between
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          widget.examTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('exams')
            .doc(widget.examId)
            .collection('questions')
            .orderBy('order')
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snap.data!.docs;
          final questions = _questionDocs(all);

          if (questions.isEmpty) {
            return const Center(child: Text('No questions in this exam.'));
          }

          // —— Finished ——
          if (_qIndex >= questions.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 56,
                      color: AppTheme.academicGold,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Done! Score: $_score / ${questions.length}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _score == questions.length
                          ? 'Perfect practice!'
                          : 'Review wrong answers and try again.',
                      style: const TextStyle(color: AppTheme.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.royalBlue,
                        minimumSize: const Size(200, 48),
                      ),
                      onPressed: () {
                        setState(() {
                          _qIndex = 0;
                          _selected = null;
                          _revealed = false;
                          _score = 0;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      child: const Text('Practice again'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          final qDoc = questions[_qIndex];
          final d = qDoc.data() as Map<String, dynamic>;
          final options = List<String>.from(d['options'] ?? []);
          final correct = d['correctIndex'] as int? ?? 0;
          final explanation = d['explanation']?.toString() ?? '';
          final text = cleanQuestionText(d['text']?.toString() ?? '');
          final passage = _passageFor(all, qDoc);
          const labels = ['ক', 'খ', 'গ', 'ঘ'];
          final progress = (_qIndex + 1) / questions.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              // Progress
              Row(
                children: [
                  Text(
                    'Question ${_qIndex + 1} of ${questions.length}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.royalBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor: Colors.grey.shade200,
                  color: AppTheme.royalBlue,
                ),
              ),
              const SizedBox(height: 16),

              // উদ্দীপক (if previous item is passage)
              if (passage != null && passage.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD4A333),
                      width: 1.3,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'উদ্দীপক',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: Color(0xFF8B6914),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        passage,
                        style: _bn.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Question card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTheme.royalBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_qIndex + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.royalBlue,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              text,
                              style: _bn.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(options.length, (i) {
                        Color? border;
                        Color? fill;
                        if (_revealed) {
                          if (i == correct) {
                            border = Colors.green;
                            fill = Colors.green.withOpacity(0.12);
                          } else if (i == _selected && i != correct) {
                            border = Colors.red;
                            fill = Colors.red.withOpacity(0.1);
                          }
                        } else if (_selected == i) {
                          border = AppTheme.royalBlue;
                          fill = AppTheme.royalBlue.withOpacity(0.08);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: fill ?? Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _revealed
                                  ? null
                                  : () => setState(() => _selected = i),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: border ?? Colors.grey.shade300,
                                    width: border != null ? 1.5 : 1,
                                  ),
                                ),
                                child: Text(
                                  '(${i < labels.length ? labels[i] : String.fromCharCode(65 + i)})  ${options[i]}',
                                  style: _bn.copyWith(
                                    fontSize: 14.5,
                                    fontWeight: _selected == i
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Feedback
              if (_revealed && _selected != correct) ...[
                const SizedBox(height: 12),
                Card(
                  color: Colors.green.withOpacity(0.08),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Correct: (${correct < labels.length ? labels[correct] : String.fromCharCode(65 + correct)})  ${correct < options.length ? options[correct] : ''}',
                          style: _bn.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.green.shade800,
                          ),
                        ),
                        if (explanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            explanation,
                            style: _bn.copyWith(height: 1.4, fontSize: 13.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],

              if (_revealed && _selected == correct) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    const Text(
                      'Correct!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                if (explanation.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    explanation,
                    style: _bn.copyWith(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),
              if (!_revealed)
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.royalBlue,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _selected == null
                      ? null
                      : () {
                          final ok = _selected == correct;
                          setState(() {
                            _revealed = true;
                            if (ok) _score++;
                          });
                        },
                  child: const Text(
                    'Check answer',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.academicGold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _qIndex++;
                      _selected = null;
                      _revealed = false;
                    });
                  },
                  child: Text(
                    _qIndex + 1 >= questions.length
                        ? 'Finish'
                        : 'Next question',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}