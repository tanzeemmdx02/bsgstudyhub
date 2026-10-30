import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/ai_mcq_service.dart';
import '../theme/app_theme.dart';
import '../utils/html_pdf_printer.dart';

const _bn = TextStyle(
  fontFamily: 'Noto Sans Bengali',
  fontFamilyFallback: [
    'Hind Siliguri',
    'Kalpurush',
    'SolaimanLipi',
    'Arial',
  ],
  height: 1.5,
);

class CreateMcqScreen extends StatefulWidget {
  final String examId;
  final String examTitle;

  const CreateMcqScreen({
    super.key,
    required this.examId,
    required this.examTitle,
  });

  @override
  State<CreateMcqScreen> createState() => _CreateMcqScreenState();
}

class _CreateMcqScreenState extends State<CreateMcqScreen> {
  final _mainTextCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _opts = List.generate(4, (_) => TextEditingController());
  int _correct = 0;
  bool _saving = false;
  bool _showManualForm = true;
  bool _isPassage = false; // false = Question (Q), true = Passage (P)

  final _appNameCtrl = TextEditingController(text: 'BSGD ACADEMY');
  final _addressCtrl = TextEditingController(
    text: 'ছলিমা ভিলা, রিকাবীবাজার, সিলেট\nমোবাইল: ০১৭১২ ৩১৭২১৪',
  );
  final _classCtrl = TextEditingController(text: 'একাদশ-দ্বাদশ');
  final _subjectCtrl = TextEditingController(text: 'হিসাববিজ্ঞান');
  final _fullMarkCtrl = TextEditingController(text: '২০');
  final _timeCtrl = TextEditingController(text: '৩০ মিনিট');

  CollectionReference get _qCol => FirebaseFirestore.instance
      .collection('exams')
      .doc(widget.examId)
      .collection('questions');

  @override
  void dispose() {
    _mainTextCtrl.dispose();
    _expCtrl.dispose();
    for (final c in _opts) {
      c.dispose();
    }
    _appNameCtrl.dispose();
    _addressCtrl.dispose();
    _classCtrl.dispose();
    _subjectCtrl.dispose();
    _fullMarkCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  void _clearInlineForm() {
    _mainTextCtrl.clear();
    _expCtrl.clear();
    for (final c in _opts) {
      c.clear();
    }
    setState(() => _correct = 0);
  }

  void _showLoading(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(msg, style: _bn, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _closeLoading() {
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  /// Helper to send a notification to Firestore whenever questions are added or uploaded
  Future<void> _sendMcqUploadNotification({required int questionCount}) async {
    try {
      if (questionCount <= 0) return;
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'New MCQ Exam Uploaded! 📝',
        'body': 'A new quiz "${widget.examTitle}" has been updated with $questionCount new question(s). Check it out now!',
        'type': 'mcq_exam',
        'examId': widget.examId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Failed to send MCQ notification: $e');
    }
  }

  /// Removes printed question serial numbers (e.g., "১০. ", "9. ", "১) ", "প্রশ্ন ১০: ")
  /// STRICTLY PRESERVES all numbers inside the question body (e.g. "৪,৭৯৫ টাকা") and Roman numerals ("i.", "ii.")
  String _cleanLeadingSerial(String raw) {
    var t = raw.trim();
    t = t.replaceFirst(
      RegExp(r'^(?:(?:প্রশ্ন|question|q)\s*[:\.]?\s*)?(?:[০-৯]+|[0-9]+)\s*[\.\)\]\|:–-]\s*', caseSensitive: false),
      '',
    );
    return t.trim();
  }

  /// Inserts a new Question or Passage at the TOP (order: 1)
  Future<void> _saveInlineItem({required bool clearAfter}) async {
    final rawText = _mainTextCtrl.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isPassage
                ? 'Please write the passage / উদ্দীপক'
                : 'Please write the question',
          ),
        ),
      );
      return;
    }

    final text = _isPassage ? rawText : _cleanLeadingSerial(rawText);
    final options = _opts.map((c) => c.text.trim()).toList();
    if (!_isPassage && options.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all 4 options')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = await _qCol.orderBy('order').get();
      final batch = FirebaseFirestore.instance.batch();

      // Shift existing items down by +1
      for (final doc in existing.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final oldOrder = (d['order'] as num?)?.toInt() ?? 0;
        batch.update(doc.reference, {'order': oldOrder + 1});
      }

      final newDoc = _qCol.doc();
      batch.set(newDoc, {
        'type': _isPassage ? 'passage' : 'question',
        'text': text,
        'options': _isPassage ? <String>[] : options,
        'correctIndex': _isPassage ? 0 : _correct,
        'explanation': _isPassage
            ? ''
            : (_expCtrl.text.trim().isEmpty
                ? 'Correct answer: ${options[_correct]}'
                : _expCtrl.text.trim()),
        'order': 1,
        'source': 'manual',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!_isPassage) {
        batch.update(
          FirebaseFirestore.instance.collection('exams').doc(widget.examId),
          {'questionCount': FieldValue.increment(1)},
        );
      }

      await batch.commit();

      // Trigger notification for manual MCQ addition
      if (!_isPassage) {
        await _sendMcqUploadNotification(questionCount: 1);
      }

      if (clearAfter) _clearInlineForm();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPassage
                  ? 'Passage added at the top'
                  : 'Question added at the top',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<int?> _askMcqCount() async {
    final ctrl = TextEditingController(text: '10');
    final n = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How many MCQs?'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of questions',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text.trim()) ?? 0;
              Navigator.pop(ctx, v > 0 ? v : null);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return n;
  }

  Future<void> _saveGenerated(
    List<GeneratedMcq> questions,
    String source,
  ) async {
    if (questions.isEmpty) return;
    final existing = await _qCol.get();
    var order = existing.size;
    final batch = FirebaseFirestore.instance.batch();
    var qCount = 0;

    for (final q in questions) {
      order++;
      final isPassage = q.isPassage;
      if (!isPassage) qCount++;

      batch.set(_qCol.doc(), {
        'type': isPassage ? 'passage' : 'question',
        'text': q.text,
        'options': isPassage ? <String>[] : q.options,
        'correctIndex': isPassage ? 0 : q.correctIndex,
        'explanation': isPassage
            ? ''
            : (q.explanation.isEmpty
                ? 'Correct: ${q.options[q.correctIndex]}'
                : q.explanation),
        'order': order,
        'source': source,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (qCount > 0) {
      batch.update(
        FirebaseFirestore.instance.collection('exams').doc(widget.examId),
        {'questionCount': FieldValue.increment(qCount)},
      );
    }
    await batch.commit();

    // Trigger notification for bulk/generated MCQ uploads
    await _sendMcqUploadNotification(questionCount: qCount);
  }

  Future<void> _uploadAiMcq() async {
    if (!AiMcqService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Need GEMINI_API_KEY.\n'
            'flutter run ... --dart-define=GEMINI_API_KEY=your_key',
          ),
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    final count = await _askMcqCount();
    if (count == null || count < 1) return;

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'txt'],
      );
      if (file == null) return;
      if (!mounted) return;
      _showLoading('AI generating $count MCQs…');

      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      List<GeneratedMcq> questions;

      if (name.endsWith('.txt')) {
        questions = await AiMcqService.fromText(
          utf8.decode(bytes),
          extractOnly: false,
          questionCount: count,
        );
      } else if (name.endsWith('.pdf')) {
        questions = await AiMcqService.fromPdf(
          bytes,
          extractOnly: false,
          questionCount: count,
        );
      } else {
        final mime = name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        questions = await AiMcqService.fromImage(
          bytes: bytes,
          mimeType: mime,
          extractOnly: false,
          questionCount: count,
        );
      }

      final onlyQ = questions.where((q) => !q.isPassage).toList();
      if (onlyQ.length > count) {
        questions = [
          ...questions.where((q) => q.isPassage),
          ...onlyQ.take(count),
        ];
      }

      if (!mounted) return;
      _closeLoading();

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI returned no questions')),
        );
        return;
      }

      setState(() => _saving = true);
      await _saveGenerated(questions, 'ai_generate');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI generated ${questions.where((q) => !q.isPassage).length} MCQs',
          ),
        ),
      );
    } catch (e) {
      _closeLoading();
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI failed: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _uploadExistingMcqPaper() async {
    if (!AiMcqService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Need GEMINI_API_KEY.\n'
            'flutter run ... --dart-define=GEMINI_API_KEY=your_key',
          ),
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (file == null) return;
      if (!mounted) return;
      _showLoading('Reading MCQ paper… extracting Q + উদ্দীপক…');

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw Exception('Empty file');
      if (bytes.length > 8 * 1024 * 1024) {
        throw Exception('File larger than 8 MB. Use a smaller image/PDF.');
      }

      final name = file.name.toLowerCase();
      final List<GeneratedMcq> questions;

      if (name.endsWith('.pdf')) {
        questions = await AiMcqService.fromPdf(bytes, extractOnly: true);
      } else {
        final mime = name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        questions = await AiMcqService.fromImage(
          bytes: bytes,
          mimeType: mime,
          extractOnly: true,
        );
      }

      if (!mounted) return;
      _closeLoading();

      if (questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions found in the paper')),
        );
        return;
      }

      setState(() => _saving = true);
      await _saveGenerated(questions, 'upload_mcq_paper');
      if (!mounted) return;
      setState(() => _saving = false);

      final pc = questions.where((q) => q.isPassage).length;
      final qc = questions.where((q) => !q.isPassage).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported: $pc passage(s), $qc question(s)')),
      );
    } catch (e) {
      _closeLoading();
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload MCQ failed: $e'),
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<void> _editItemModal(String docId, Map<String, dynamic> data) async {
    final isPassage = (data['type']?.toString() ?? 'question') == 'passage';
    final editMainCtrl =
        TextEditingController(text: data['text']?.toString() ?? '');
    final editExpCtrl =
        TextEditingController(text: data['explanation']?.toString() ?? '');
    final existingOpts = List<String>.from(data['options'] ?? ['', '', '', '']);
    while (existingOpts.length < 4) {
      existingOpts.add('');
    }
    final editOpts = List.generate(
      4,
      (i) => TextEditingController(text: existingOpts[i]),
    );
    var editCorrect = data['correctIndex'] as int? ?? 0;
    if (editCorrect < 0 || editCorrect > 3) editCorrect = 0;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isPassage ? 'Edit Passage / উদ্দীপক' : 'Edit MCQ Question',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: editMainCtrl,
                    maxLines: isPassage ? 6 : 3,
                    style: _bn,
                    decoration: InputDecoration(
                      labelText: isPassage ? 'Passage *' : 'Question *',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (!isPassage) ...[
                    const SizedBox(height: 12),
                    ...List.generate(4, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: i,
                              groupValue: editCorrect,
                              onChanged: (v) =>
                                  setDialogState(() => editCorrect = v ?? 0),
                            ),
                            Expanded(
                              child: TextField(
                                controller: editOpts[i],
                                style: _bn,
                                decoration: InputDecoration(
                                  labelText:
                                      'Option ${String.fromCharCode(65 + i)} *',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    TextField(
                      controller: editExpCtrl,
                      maxLines: 2,
                      style: _bn,
                      decoration: const InputDecoration(
                        labelText: 'Explanation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (updated != true) {
      editMainCtrl.dispose();
      editExpCtrl.dispose();
      for (final c in editOpts) {
        c.dispose();
      }
      return;
    }

    try {
      final updatedText = isPassage
          ? editMainCtrl.text.trim()
          : _cleanLeadingSerial(editMainCtrl.text.trim());

      await _qCol.doc(docId).update({
        'text': updatedText,
        if (!isPassage) 'options': editOpts.map((c) => c.text.trim()).toList(),
        if (!isPassage) 'correctIndex': editCorrect,
        if (!isPassage) 'explanation': editExpCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPassage ? 'Passage updated' : 'Question updated'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }

    editMainCtrl.dispose();
    editExpCtrl.dispose();
    for (final c in editOpts) {
      c.dispose();
    }
  }

  Future<void> _deleteItem(
    DocumentReference ref, {
    required bool isQuestion,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await ref.delete();
    if (isQuestion) {
      await FirebaseFirestore.instance
          .collection('exams')
          .doc(widget.examId)
          .update({'questionCount': FieldValue.increment(-1)});
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deleted successfully')),
      );
    }
  }

  Future<void> _reorder(
    int oldIndex,
    int newIndex,
    List<QueryDocumentSnapshot> docs,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final ids = docs.map((d) => d.id).toList();
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < ids.length; i++) {
      batch.update(_qCol.doc(ids[i]), {'order': i + 1});
    }
    await batch.commit();
  }

  Future<void> _publish() async {
    await FirebaseFirestore.instance
        .collection('exams')
        .doc(widget.examId)
        .update({'published': true});

    // Also trigger a notification when published explicitly
    try {
      final snap = await _qCol.get();
      final qCount = snap.docs.where((doc) => (doc.data() as Map<String, dynamic>)['type'] == 'question').length;
      if (qCount > 0) {
        await _sendMcqUploadNotification(questionCount: qCount);
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam published for students & notification sent')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _exportBengaliPdf(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return;

    final appName = _appNameCtrl.text.trim();
    final address = _addressCtrl.text.trim().replaceAll('\n', '<br>');
    final subject = _subjectCtrl.text.trim().isNotEmpty
        ? _subjectCtrl.text.trim()
        : widget.examTitle;
    final className = _classCtrl.text.trim();
    final fullMark = _fullMarkCtrl.text.trim();
    final time = _timeCtrl.text.trim();

    final isExamBangla = isBanglaText(widget.examTitle) || isBanglaText(subject);
    final bnLabels = ['ক', 'খ', 'গ', 'ঘ'];
    final enLabels = ['A', 'B', 'C', 'D'];
    final questionsHtml = StringBuffer();
    var qNum = 0;

    for (final doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      final isPassage = (d['type']?.toString() ?? 'question') == 'passage';
      final text = const HtmlEscape().convert(d['text']?.toString() ?? '');
      final rawOptions = List<String>.from(d['options'] ?? []);

      if (isPassage) {
        questionsHtml.write('''
          <div class="passage-box">
            <div class="passage-tag">উদ্দীপক</div>
            <div class="passage-content">$text</div>
          </div>
        ''');
      } else {
        qNum++;
        final isQBangla = isBanglaText(d['text']?.toString() ?? '') || isExamBangla;
        final qNumFormatted = isQBangla ? toBanglaDigits(qNum) : '$qNum';
        final labels = isQBangla ? bnLabels : enLabels;

        final options =
            rawOptions.map((o) => const HtmlEscape().convert(o)).toList();
        final o0 = options.isNotEmpty ? options[0] : '';
        final o1 = options.length > 1 ? options[1] : '';
        final o2 = options.length > 2 ? options[2] : '';
        final o3 = options.length > 3 ? options[3] : '';

        questionsHtml.write('''
          <div class="question-block">
            <div class="q-title"><strong>$qNumFormatted.</strong> $text</div>
            <div class="options-grid">
              <div class="opt">(${labels[0]}) $o0</div>
              <div class="opt">(${labels[1]}) $o1</div>
              <div class="opt">(${labels[2]}) $o2</div>
              <div class="opt">(${labels[3]}) $o3</div>
            </div>
          </div>
        ''');
      }
    }

    final fullHtml = '''
<!DOCTYPE html>
<html lang="bn">
<head>
  <meta charset="utf-8">
  <title>${const HtmlEscape().convert(widget.examTitle)}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    @page { size: A4 portrait; margin: 15mm 18mm; }
    * { box-sizing: border-box; }
    body {
      font-family: 'Noto Sans Bengali', Roboto, sans-serif;
      margin: 0; padding: 0; background: #fff; color: #000;
      font-size: 13.5px; line-height: 1.5;
      -webkit-print-color-adjust: exact !important;
      print-color-adjust: exact !important;
    }
    .header { text-align: center; margin-bottom: 12px; }
    .institution-name { font-size: 21px; font-weight: 800; margin: 0; }
    .address { font-size: 11px; color: #333; margin: 3px 0 10px; line-height: 1.4; }
    .subject-pill {
      display: inline-block; background: #eeeeee;
      padding: 3px 16px; border-radius: 4px; font-weight: 700; font-size: 13px;
    }
    .meta-row {
      display: flex; justify-content: space-between; font-size: 13px;
      font-weight: 600; margin-top: 10px; padding-bottom: 6px;
      border-bottom: 1.5px solid #000;
    }
    .passage-box {
      border: 1.2px solid #555; background: #fffdf5;
      padding: 10px 14px; margin: 14px 0; border-radius: 4px;
      page-break-inside: avoid;
    }
    .passage-tag { font-weight: 800; font-size: 11px; color: #8c6d1f; margin-bottom: 4px; }
    .passage-content { font-weight: 600; font-size: 13px; line-height: 1.55; }
    .question-block { margin-bottom: 14px; page-break-inside: avoid; }
    .q-title { font-size: 13.5px; margin-bottom: 6px; line-height: 1.45; }
    .options-grid {
      display: grid; grid-template-columns: 1fr 1fr;
      row-gap: 5px; column-gap: 20px; padding-left: 18px;
    }
    .opt { font-size: 13px; }
  </style>
</head>
<body>
  <div class="header">
    <div class="institution-name">${const HtmlEscape().convert(appName)}</div>
    <div class="address">$address</div>
    <div class="subject-pill">${const HtmlEscape().convert(subject)}</div>
  </div>
  <div class="meta-row">
    <div>শ্রেণি: ${const HtmlEscape().convert(className)}</div>
    <div>পূর্ণমান: ${const HtmlEscape().convert(fullMark)}</div>
    <div>সময়: ${const HtmlEscape().convert(time)}</div>
  </div>
  <div style="height: 12px;"></div>
  $questionsHtml
  <script>
    window.addEventListener('load', () => {
      setTimeout(() => { window.print(); }, 350);
    });
  </script>
</body>
</html>
''';

    try {
      await printOrExportHtml(fullHtml, widget.examTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _openPrintHeaderDialog(List<QueryDocumentSnapshot> docs) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exam Header Details', style: _bn),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _appNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Institution Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                style: _bn,
                decoration: const InputDecoration(
                  labelText: 'Address & Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _classCtrl,
                style: _bn,
                decoration: const InputDecoration(
                  labelText: 'Class',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _subjectCtrl,
                style: _bn,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fullMarkCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Mark',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _timeCtrl,
                      style: _bn,
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export / Print PDF'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await _exportBengaliPdf(docs);
    }
  }

  Widget _buildQPButtonToggle() {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _isPassage = !_isPassage),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 68,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF00965E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              alignment:
                  _isPassage ? Alignment.centerLeft : Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  _isPassage ? 'Q' : 'P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              alignment:
                  _isPassage ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
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
        title: Text(
          widget.examTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _qCol.orderBy('order').snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              return IconButton(
                tooltip: 'Export PDF / Print',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed:
                    docs.isEmpty ? null : () => _openPrintHeaderDialog(docs),
              );
            },
          ),
          TextButton(
            onPressed: _publish,
            child: const Text(
              'Publish',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Manage Exam Questions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _uploadAiMcq,
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('AI MCQ'),
              ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _uploadExistingMcqPaper,
                icon: const Icon(Icons.quiz_outlined, size: 18),
                label: const Text('Upload MCQ'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.royalBlue,
                ),
                onPressed: () {
                  setState(() => _showManualForm = !_showManualForm);
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Create Manual MCQ'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AiMcqService.isConfigured
                ? 'AI MCQ: enter count, upload notes → new questions.\n'
                    'Upload MCQ: upload paper → extract Q + উদ্দীপক.\n'
                    'Drag to reorder. Expand a question to see options.'
                : 'Start with --dart-define=GEMINI_API_KEY=... for AI.',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),

          if (_showManualForm) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      TextField(
                        controller: _mainTextCtrl,
                        minLines: _isPassage ? 4 : 2,
                        maxLines: _isPassage ? 8 : 4,
                        style: _bn,
                        decoration: InputDecoration(
                          labelText: _isPassage ? 'Passage*' : 'Question *',
                          labelStyle:
                              const TextStyle(fontWeight: FontWeight.bold),
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                          contentPadding:
                              const EdgeInsets.fromLTRB(12, 16, 76, 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, right: 10),
                        child: _buildQPButtonToggle(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isPassage ? 0.32 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isPassage,
                      child: Column(
                        children: List.generate(4, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: i,
                                  groupValue: _correct,
                                  onChanged: _isPassage
                                      ? null
                                      : (v) =>
                                          setState(() => _correct = v ?? 0),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _opts[i],
                                    style: _bn,
                                    decoration: InputDecoration(
                                      labelText:
                                          'Option ${String.fromCharCode(65 + i)} *',
                                      border: const OutlineInputBorder(),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isPassage ? 0.32 : 1.0,
                    child: IgnorePointer(
                      ignoring: _isPassage,
                      child: TextField(
                        controller: _expCtrl,
                        minLines: 1,
                        maxLines: 3,
                        style: _bn,
                        decoration: const InputDecoration(
                          labelText: 'Explanation (shown if student is wrong)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.black45),
                          ),
                          onPressed: _saving
                              ? null
                              : () => _saveInlineItem(clearAfter: true),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add More'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A333),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _saving
                              ? null
                              : () => _saveInlineItem(clearAfter: true),
                          child: Text(
                            _saving
                                ? 'Saving…'
                                : (_isPassage
                                    ? 'Save Passage'
                                    : 'Save question'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Text(
            'Questions in this exam',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          StreamBuilder<QuerySnapshot>(
            stream: _qCol.orderBy('order').snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return Text('Error: ${snap.error}');
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No questions added yet.'),
                  ),
                );
              }

              var qNum = 0;
              return ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(10),
                    child: child,
                  );
                },
                itemCount: docs.length,
                onReorder: (a, b) => _reorder(a, b, docs),
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final d = doc.data() as Map<String, dynamic>;
                  final isPassage =
                      (d['type']?.toString() ?? 'question') == 'passage';
                  final opts = List<String>.from(d['options'] ?? []);
                  final ci = d['correctIndex'] as int? ?? 0;
                  final text = d['text']?.toString() ?? '';
                  final explanation = d['explanation']?.toString() ?? '';

                  // —— PASSAGE CARD ——
                  if (isPassage) {
                    return Container(
                      key: ValueKey(doc.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9EC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFD4A333),
                          width: 1.4,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.drag_handle,
                                color: Color(0xFF8B6914),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'উদ্দীপক (Passage)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: Color(0xFF8B6914),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  text,
                                  style: _bn.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () => _editItemModal(doc.id, d),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () => _deleteItem(
                                  doc.reference,
                                  isQuestion: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }

                  // —— QUESTION CARD (expandable) ——
                  qNum++;
                  final displayNum = qNum;

                  // 1. Language detection (checks question text & exam title)
                  final isBangla = isBanglaText(text) || isBanglaText(widget.examTitle);

                  // 2. Localized badge: '১', '২', '৩' for Bangla; '1', '2', '3' for English
                  final badgeLabel = isBangla ? toBanglaDigits(displayNum) : '$displayNum';

                  // 3. Option prefixes: 'ক', 'খ', 'গ', 'ঘ' for Bangla; 'A', 'B', 'C', 'D' for English
                  const bnLabels = ['ক', 'খ', 'গ', 'ঘ'];
                  const enLabels = ['A', 'B', 'C', 'D'];
                  final currentLabels = isBangla ? bnLabels : enLabels;
                  final correctPrefix = ci < 4 ? currentLabels[ci] : '$ci';

                  return Card(
                    key: ValueKey(doc.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReorderableDragStartListener(
                            index: i,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                          // Dynamic Purple/Blue Circular Badge
                          CircleAvatar(
                            radius: 13,
                            backgroundColor:
                                AppTheme.royalBlue.withOpacity(0.12),
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                fontSize: isBangla ? 13 : 11,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.royalBlue,
                                fontFamily: isBangla ? 'Noto Sans Bengali' : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _bn.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        isBangla
                            ? 'সঠিক উত্তর: $correctPrefix. ${ci < opts.length ? opts[ci] : ''}'
                            : 'Correct: $correctPrefix. ${ci < opts.length ? opts[ci] : ''}',
                        style: const TextStyle(
                          color: AppTheme.accentEmerald,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                              size: 20,
                            ),
                            onPressed: () => _editItemModal(doc.id, d),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () => _deleteItem(
                              doc.reference,
                              isQuestion: true,
                            ),
                          ),
                        ],
                      ),
                      children: [
                        const Divider(),
                        SelectableText(
                          text,
                          style: _bn.copyWith(fontSize: 14, height: 1.45),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(opts.length, (optIdx) {
                          final isCorrect = optIdx == ci;
                          final optLabel = optIdx < 4 ? currentLabels[optIdx] : String.fromCharCode(65 + optIdx);

                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCorrect
                                    ? Colors.green
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              '$optLabel. ${opts[optIdx]}${isCorrect ? '  ✓' : ''}',
                              style: _bn.copyWith(
                                fontWeight: isCorrect
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isCorrect
                                    ? Colors.green.shade800
                                    : null,
                              ),
                            ),
                          );
                        }),
                        if (explanation.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            isBangla ? 'ব্যাখ্যা: $explanation' : 'Explanation: $explanation',
                            style: _bn.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}