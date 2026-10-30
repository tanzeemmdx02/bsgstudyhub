import 'dart:convert';
import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/ai_mcq_service.dart';
import '../theme/app_theme.dart';

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

class AiPoolStatusCard extends StatefulWidget {
  const AiPoolStatusCard({super.key});

  @override
  State<AiPoolStatusCard> createState() => _AiPoolStatusCardState();
}

class _AiPoolStatusCardState extends State<AiPoolStatusCard> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await AiMcqService.syncFromFirestore();
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAddKeyDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: AppTheme.royalBlue),
            SizedBox(width: 8),
            Text('Add Gemini API Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Paste your API key here...',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final key = ctrl.text.trim();
              if (key.isNotEmpty) {
                await AiMcqService.addApiKey(key);
                if (mounted) setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Add Key'),
          ),
        ],
      ),
    );
  }

  void _showEditKeyDialog(int index, String oldKey) {
    final ctrl = TextEditingController(text: oldKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Edit API Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final key = ctrl.text.trim();
              if (key.isNotEmpty) {
                await AiMcqService.editApiKey(index, key);
                if (mounted) setState(() {});
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _maskKey(String key) {
    if (key.length <= 10) return key;
    return '${key.substring(0, 6)}••••••••${key.substring(key.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final keys = AiMcqService.keyPool;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.indigo.shade50.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigo.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.royalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.psychology_rounded, color: AppTheme.royalBlue, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Engine & API Pool',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.2),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage rotation keys & active Gemini model',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.royalBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _showAddKeyDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add New API', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Colors.black12),
          ),
          Row(
            children: [
              const Text('Active Gemini Model:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: AiMcqService.freeModels.contains(AiMcqService.selectedModel)
                          ? AiMcqService.selectedModel
                          : AiMcqService.freeModels.first,
                      isExpanded: true,
                      items: AiMcqService.freeModels.map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(m, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val != null) {
                          await AiMcqService.setModel(val);
                          if (mounted) setState(() {});
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Configured Keys in Database Pool',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          _isLoading
              ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
              : keys.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber),
                          SizedBox(width: 10),
                          Text('No API keys in pool. Add an API key to enable AI features.', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: keys.length,
                      itemBuilder: (ctx, idx) {
                        final key = keys[idx];
                        final displayNum = idx + 1;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppTheme.royalBlue.withOpacity(0.1),
                                child: Text('$displayNum', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.royalBlue)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _maskKey(key),
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                tooltip: 'Edit Key',
                                onPressed: () => _showEditKeyDialog(idx, key),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                tooltip: 'Delete Key',
                                onPressed: () async {
                                  await AiMcqService.removeApiKey(idx);
                                  if (mounted) setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

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
  bool _showManualForm = false;
  bool _isPassage = false;

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

  String _cleanLeadingSerial(String raw) {
    var t = raw.trim();
    t = t.replaceFirst(
      RegExp(r'^(?:(?:প্রশ্ন|question|q)\s*[:\.]?\s*)?(?:[০-৯]+|[0-9]+)\s*[\.\)\]\|:–-]\s*', caseSensitive: false),
      '',
    );
    return t.trim();
  }

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
    await _sendMcqUploadNotification(questionCount: qCount);
  }

  Future<void> _uploadAiMcq() async {
    if (!AiMcqService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Need GEMINI_API_KEY.\n'
            'Add keys via API pool settings above.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    final count = await _askMcqCount();
    if (count == null || count < 1) return;

    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'txt'],
      );
      if (pickedFiles == null || pickedFiles.isEmpty) return;
      final file = pickedFiles.first;
      if (!mounted) return;
      _showLoading('AI generating $count MCQs…');

      Uint8List? bytes;
      try {
        bytes = (file as dynamic).bytes as Uint8List?;
      } catch (_) {}

      if (bytes == null) {
        try {
          bytes = await file.xFile.readAsBytes();
        } catch (_) {}
      }

      if (bytes == null && file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) throw Exception('Empty file data');

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
            'Add keys via API pool settings above.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
      return;
    }

    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (pickedFiles == null || pickedFiles.isEmpty) return;
      final file = pickedFiles.first;
      if (!mounted) return;
      _showLoading('Reading MCQ paper… extracting Q + উদ্দীপক…');

      Uint8List? bytes;
      try {
        bytes = (file as dynamic).bytes as Uint8List?;
      } catch (_) {}

      if (bytes == null) {
        try {
          bytes = await file.xFile.readAsBytes();
        } catch (_) {}
      }

      if (bytes == null && file.path != null) {
        bytes = await io.File(file.path!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) throw Exception('Empty file data');

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

  Future<void> _deleteItem(String docId, bool isQuestion) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('This will remove this item permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _qCol.doc(docId).delete();
      if (isQuestion) {
        await FirebaseFirestore.instance.collection('exams').doc(widget.examId).update({
          'questionCount': FieldValue.increment(-1),
        });
      }
    }
  }

  Future<void> _publish() async {
    await FirebaseFirestore.instance
        .collection('exams')
        .doc(widget.examId)
        .update({'published': true});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam published for students & notification sent')),
      );
      Navigator.pop(context);
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
          const AiPoolStatusCard(),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Exam Questions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.royalBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() => _showManualForm = !_showManualForm);
                },
                icon: Icon(_showManualForm ? Icons.close : Icons.edit, size: 16),
                label: Text(_showManualForm ? 'Hide Form' : 'Create Manual MCQ'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : _uploadAiMcq,
                icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.indigo),
                label: const Text('AI MCQ Generator'),
              ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _uploadExistingMcqPaper,
                icon: const Icon(Icons.upload_file_rounded, size: 18, color: Colors.green),
                label: const Text('Upload MCQ Paper (PDF/Img)'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_showManualForm) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.indigo.shade100),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
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
                          labelText: _isPassage ? 'Passage / উদ্দীপক *' : 'Question Text *',
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.fromLTRB(12, 16, 76, 16),
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
                                      : (v) => setState(() => _correct = v ?? 0),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _opts[i],
                                    style: _bn,
                                    decoration: InputDecoration(
                                      labelText: 'Option ${String.fromCharCode(65 + i)} *',
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _saving ? null : () => _saveInlineItem(clearAfter: true),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Another'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A333),
                            foregroundColor: Colors.black87,
                          ),
                          onPressed: _saving ? null : () => _saveInlineItem(clearAfter: true),
                          child: Text(_saving ? 'Saving…' : 'Save Question'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Live Rendered Questions and Passages List
          const Text(
            'Exam Questions & Passages Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blueGrey),
          ),
          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: _qCol.orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(30),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No questions added yet.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text('Use "AI MCQ Generator" or "Upload MCQ Paper" above to import automatically.', style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              var qCounter = 0;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (ctx, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final type = data['type']?.toString() ?? 'question';
                  final isPassage = type == 'passage';
                  final text = data['text']?.toString() ?? '';

                  if (isPassage) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4A333), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.article_rounded, size: 16, color: Color(0xFF8B6914)),
                                  SizedBox(width: 6),
                                  Text('উদ্দীপক / Passage', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF8B6914))),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                onPressed: () => _deleteItem(doc.id, false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(text, style: _bn.copyWith(fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    );
                  }

                  qCounter++;
                  final options = List<String>.from(data['options'] ?? []);
                  final correctIdx = data['correctIndex'] as int? ?? 0;
                  final explanation = data['explanation']?.toString() ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.royalBlue.withOpacity(0.1),
                                child: Text('$qCounter', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.royalBlue)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  text,
                                  style: _bn.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                onPressed: () => _deleteItem(doc.id, true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(options.length, (oi) {
                            final isCorrect = oi == correctIdx;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCorrect ? Colors.green.withOpacity(0.08) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isCorrect ? Colors.green.shade300 : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${String.fromCharCode(65 + oi)}. ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isCorrect ? Colors.green.shade700 : Colors.black87),
                                  ),
                                  Expanded(
                                    child: Text(
                                      options[oi],
                                      style: _bn.copyWith(color: isCorrect ? Colors.green.shade900 : Colors.black87, fontWeight: isCorrect ? FontWeight.w700 : FontWeight.normal),
                                    ),
                                  ),
                                  if (isCorrect)
                                    const Icon(Icons.check_circle_rounded, size: 16, color: Colors.green),
                                ],
                              ),
                            );
                          }),
                          if (explanation.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Explanation: $explanation',
                              style: _bn.copyWith(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ],
                      ),
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