import 'dart:convert';
import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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

class AiPoolStatusCard extends StatefulWidget {
  const AiPoolStatusCard({super.key});

  @override
  State<AiPoolStatusCard> createState() => _AiPoolStatusCardState();
}

class _AiPoolStatusCardState extends State<AiPoolStatusCard> {
  bool _isLoading = true;
  final Set<int> _disabledIndices = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await AiMcqService.syncFromFirestore();
    if (mounted) {
      _disabledIndices.clear();
      // Keep all deactivated by default except the first one (index 0)
      for (int i = 1; i < AiMcqService.keyPool.length; i++) {
        _disabledIndices.add(i);
      }
      setState(() => _isLoading = false);
    }
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
                if (AiMcqService.keyPool.length > 1) {
                  _disabledIndices.add(AiMcqService.keyPool.length - 1);
                }
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
                        final isActive = !_disabledIndices.contains(idx);

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
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? Colors.black87 : Colors.grey,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (_disabledIndices.contains(idx)) {
                                      _disabledIndices.remove(idx);
                                    } else {
                                      _disabledIndices.add(idx);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: isActive ? Colors.green.shade300 : Colors.red.shade300),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Deactive',
                                    style: TextStyle(
                                      color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
  bool _showManualForm = true;
  bool _isPassage = false;

  late String _examTitle;

  final _appNameCtrl = TextEditingController(text: 'BSGD ACADEMY');
  final _addressCtrl = TextEditingController(
    text: 'ছলিমা ভিলা, রিকাবীবাজার, সিলেট\nমোবাইল: ০১৭১২ ৩১৭২১৪',
  );
  final _classCtrl = TextEditingController(text: 'একাদশ-দ্বাদশ');
  final _subjectCtrl = TextEditingController(text: 'হিসাববিজ্ঞান');
  final _fullMarkCtrl = TextEditingController(text: '20');
  final _timeCtrl = TextEditingController(text: '30');

  DateTime? _startDate;
  DateTime? _expireDate;
  final _attemptsCtrl = TextEditingController(text: '1');
  bool _isPaid = false;
  final _priceCtrl = TextEditingController(text: '0');

  CollectionReference get _qCol => FirebaseFirestore.instance
      .collection('exams')
      .doc(widget.examId)
      .collection('questions');

  @override
  void initState() {
    super.initState();
    _examTitle = widget.examTitle;
    _loadExamDetailsFromFirestore();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Select Date';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  DateTime? _parseDateTime(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  Future<void> _loadExamDetailsFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('exams').doc(widget.examId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            if (data['title'] != null && data['title'].toString().trim().isNotEmpty) {
              _examTitle = data['title'].toString().trim();
            }
            if (data['class'] != null && data['class'].toString().trim().isNotEmpty) {
              _classCtrl.text = data['class'].toString().trim();
            }
            if (data['subject'] != null && data['subject'].toString().trim().isNotEmpty) {
              _subjectCtrl.text = data['subject'].toString().trim();
            }
            if (data['time'] != null && data['time'].toString().trim().isNotEmpty) {
              _timeCtrl.text = data['time'].toString().trim();
            }
            if (data['fullMarks'] != null && data['fullMarks'].toString().trim().isNotEmpty) {
              _fullMarkCtrl.text = data['fullMarks'].toString().trim();
            }
            if (data['institution'] != null && data['institution'].toString().trim().isNotEmpty) {
              _appNameCtrl.text = data['institution'].toString().trim();
            }
            if (data['address'] != null && data['address'].toString().trim().isNotEmpty) {
              _addressCtrl.text = data['address'].toString().trim();
            }

            _startDate = _parseDateTime(data['startDate']) ?? DateTime.now();
            _expireDate = _parseDateTime(data['expireDate']) ?? DateTime.now().add(const Duration(days: 7));

            if (data['allowedAttempts'] != null) {
              _attemptsCtrl.text = data['allowedAttempts'].toString().trim();
            }
            if (data['isPaid'] != null) {
              _isPaid = data['isPaid'] == true;
            } else if (data['pricing'] != null) {
              _isPaid = data['pricing'].toString().toLowerCase() == 'paid';
            }
            if (data['price'] != null) {
              _priceCtrl.text = data['price'].toString().trim();
            } else if (data['examPrice'] != null) {
              _priceCtrl.text = data['examPrice'].toString().trim();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load exam details: $e');
    }
  }

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
    _attemptsCtrl.dispose();
    _priceCtrl.dispose();
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
        'body': 'A new quiz "$_examTitle" has been updated with $questionCount new question(s). Check it out now!',
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

  Future<Uint8List?> _getFileBytes(PlatformFile file) async {
    try {
      return await file.readAsBytes();
    } catch (_) {
      try {
        if (file.path != null) {
          return await io.File(file.path!).readAsBytes();
        }
      } catch (_) {}
    }
    return null;
  }

  Map<String, String> _extractFromText(String raw) {
    final res = <String, String>{};
    final classMatch = RegExp(r'(?:শ্রেণি|class)\s*[:\-–]\s*([^\n\r,\|]+)', caseSensitive: false).firstMatch(raw);
    if (classMatch != null) res['class'] = classMatch.group(1)!.trim();

    final subjectMatch = RegExp(r'(?:বিষয়|subject)\s*[:\-–]\s*([^\n\r,\|]+)', caseSensitive: false).firstMatch(raw);
    if (subjectMatch != null) res['subject'] = subjectMatch.group(1)!.trim();

    final timeMatch = RegExp(r'(?:সময়|time)\s*[:\-–]\s*([^\n\r,\|]+)', caseSensitive: false).firstMatch(raw);
    if (timeMatch != null) res['time'] = timeMatch.group(1)!.trim();

    final markMatch = RegExp(r'(?:পূর্ণমান|full\s*marks?|marks?)\s*[:\-–]\s*([^\n\r,\|]+)', caseSensitive: false).firstMatch(raw);
    if (markMatch != null) res['fullMarks'] = markMatch.group(1)!.trim();

    final titleMatch = RegExp(r'(?:পরীক্ষা|exam|test|মডেল\s*টেস্ট)\s*[:\-–]?\s*([^\n\r]+)', caseSensitive: false).firstMatch(raw);
    if (titleMatch != null) res['title'] = titleMatch.group(0)!.trim();

    return res;
  }

  Future<Map<String, String>?> _extractExamMetaFromFile({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    if (!AiMcqService.isConfigured || AiMcqService.keyPool.isEmpty) return null;

    final key = AiMcqService.keyPool.first;
    final model = AiMcqService.selectedModel;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
    );

    const prompt = '''
Examine this exam paper or document header. Extract exam metadata in valid JSON format:
{
  "title": "Exam title or test name",
  "class": "Class or grade (e.g. একাদশ-দ্বাদশ or Class 10)",
  "subject": "Subject name",
  "time": "Exam duration in numbers only (e.g. 30)",
  "fullMarks": "Full marks in numbers only (e.g. 20)"
}
Return ONLY valid raw JSON with keys. Do not wrap in markdown or backticks. If any field is missing, leave it as an empty string.
''';

    try {
      final payload = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "inline_data": {
                  "mime_type": mimeType,
                  "data": base64Encode(bytes),
                }
              },
              {"text": prompt}
            ]
          }
        ]
      });

      if (!kIsWeb) {
        final client = io.HttpClient();
        final request = await client.postUrl(uri);
        request.headers.set('content-type', 'application/json');
        request.add(utf8.encode(payload));
        final response = await request.close();
        final responseBody = await response.transform(utf8.decoder).join();
        client.close();

        if (response.statusCode == 200) {
          final jsonResp = jsonDecode(responseBody) as Map<String, dynamic>;
          final candidates = jsonResp['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final text = candidates[0]['content']['parts'][0]['text'] as String? ?? '';
            final cleanJson = text.replaceAll(RegExp(r'```json|```'), '').trim();
            final Map<String, dynamic> parsed = jsonDecode(cleanJson);
            return {
              'title': parsed['title']?.toString().trim() ?? '',
              'class': parsed['class']?.toString().trim() ?? '',
              'subject': parsed['subject']?.toString().trim() ?? '',
              'time': parsed['time']?.toString().trim() ?? '',
              'fullMarks': parsed['fullMarks']?.toString().trim() ?? '',
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Metadata extraction failed: $e');
    }
    return null;
  }

  Future<void> _applyExtractedMeta(Map<String, String>? meta) async {
    if (meta == null) return;
    final updates = <String, dynamic>{};

    if (meta['title'] != null && meta['title']!.isNotEmpty) {
      _examTitle = meta['title']!;
      updates['title'] = _examTitle;
    }
    if (meta['class'] != null && meta['class']!.isNotEmpty) {
      _classCtrl.text = meta['class']!;
      updates['class'] = _classCtrl.text;
    }
    if (meta['subject'] != null && meta['subject']!.isNotEmpty) {
      _subjectCtrl.text = meta['subject']!;
      updates['subject'] = _subjectCtrl.text;
    }
    if (meta['time'] != null && meta['time']!.isNotEmpty) {
      _timeCtrl.text = meta['time']!;
      updates['time'] = _timeCtrl.text;
    }
    if (meta['fullMarks'] != null && meta['fullMarks']!.isNotEmpty) {
      _fullMarkCtrl.text = meta['fullMarks']!;
      updates['fullMarks'] = _fullMarkCtrl.text;
    }

    if (updates.isNotEmpty) {
      await FirebaseFirestore.instance.collection('exams').doc(widget.examId).update(updates);
      if (mounted) setState(() {});
    }
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
      if (pickedFiles.isEmpty) return;
      final file = pickedFiles.first;
      if (!mounted) return;
      _showLoading('AI analyzing file & generating $count MCQs…');

      final bytes = await _getFileBytes(file);
      if (bytes == null || bytes.isEmpty) throw Exception('Empty file data');

      final name = file.name.toLowerCase();
      List<GeneratedMcq> questions;

      if (name.endsWith('.txt')) {
        final content = utf8.decode(bytes);
        _applyExtractedMeta(_extractFromText(content));
        questions = await AiMcqService.fromText(
          content,
          extractOnly: false,
          questionCount: count,
        );
      } else if (name.endsWith('.pdf')) {
        _extractExamMetaFromFile(bytes: bytes, mimeType: 'application/pdf').then(_applyExtractedMeta);
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
        _extractExamMetaFromFile(bytes: bytes, mimeType: mime).then(_applyExtractedMeta);
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
            'AI generated ${questions.where((q) => !q.isPassage).length} MCQs & updated form info from file',
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
      if (pickedFiles.isEmpty) return;
      final file = pickedFiles.first;
      if (!mounted) return;
      _showLoading('Reading MCQ paper & header values from file…');

      final bytes = await _getFileBytes(file);
      if (bytes == null || bytes.isEmpty) throw Exception('Empty file data');

      final name = file.name.toLowerCase();
      final List<GeneratedMcq> questions;

      if (name.endsWith('.pdf')) {
        _extractExamMetaFromFile(bytes: bytes, mimeType: 'application/pdf').then(_applyExtractedMeta);
        questions = await AiMcqService.fromPdf(bytes, extractOnly: true);
      } else {
        final mime = name.endsWith('.png')
            ? 'image/png'
            : name.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';
        _extractExamMetaFromFile(bytes: bytes, mimeType: mime).then(_applyExtractedMeta);
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
        SnackBar(content: Text('Imported: $pc passage(s), $qc question(s) & extracted header values')),
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

  Future<void> _editExamFormDialog() async {
    final titleCtrl = TextEditingController(text: _examTitle);
    final timeCtrl = TextEditingController(text: _timeCtrl.text);
    final fullMarkCtrl = TextEditingController(text: _fullMarkCtrl.text);
    final classCtrl = TextEditingController(text: _classCtrl.text);
    final subjectCtrl = TextEditingController(text: _subjectCtrl.text);

    DateTime tempStartDate = _startDate ?? DateTime.now();
    DateTime tempExpireDate = _expireDate ?? DateTime.now().add(const Duration(days: 7));
    final attemptsCtrl = TextEditingController(text: _attemptsCtrl.text);
    bool tempIsPaid = _isPaid;
    final priceCtrl = TextEditingController(text: _priceCtrl.text);

    bool isAutoExtracting = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Exam Form Details', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.royalBlue,
                      side: const BorderSide(color: AppTheme.royalBlue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: isAutoExtracting
                        ? null
                        : () async {
                            final pickedFiles = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'txt'],
                            );
                            if (pickedFiles.isEmpty) return;

                            setDialogState(() => isAutoExtracting = true);
                            try {
                              final file = pickedFiles.first;
                              final bytes = await _getFileBytes(file);
                              if (bytes != null && bytes.isNotEmpty) {
                                final name = file.name.toLowerCase();
                                Map<String, String>? meta;
                                if (name.endsWith('.txt')) {
                                  meta = _extractFromText(utf8.decode(bytes));
                                } else {
                                  final mime = name.endsWith('.pdf')
                                      ? 'application/pdf'
                                      : name.endsWith('.png')
                                          ? 'image/png'
                                          : name.endsWith('.webp')
                                              ? 'image/webp'
                                              : 'image/jpeg';
                                  meta = await _extractExamMetaFromFile(bytes: bytes, mimeType: mime);
                                }
                                if (meta != null) {
                                  setDialogState(() {
                                    if (meta!['title']?.isNotEmpty == true) titleCtrl.text = meta['title']!;
                                    if (meta['class']?.isNotEmpty == true) classCtrl.text = meta['class']!;
                                    if (meta['subject']?.isNotEmpty == true) subjectCtrl.text = meta['subject']!;
                                    if (meta['time']?.isNotEmpty == true) timeCtrl.text = meta['time']!;
                                    if (meta['fullMarks']?.isNotEmpty == true) fullMarkCtrl.text = meta['fullMarks']!;
                                  });
                                }
                              }
                            } catch (_) {}
                            setDialogState(() => isAutoExtracting = false);
                          },
                    icon: isAutoExtracting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_fix_high_rounded, size: 20),
                    label: Text(
                      isAutoExtracting ? 'Reading details from file…' : 'Auto-fill form values from File (PDF/Image)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Exam Name / Title *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: classCtrl,
                    decoration: const InputDecoration(labelText: 'Class *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: timeCtrl,
                          decoration: const InputDecoration(labelText: 'Time (Minutes)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: fullMarkCtrl,
                          decoration: const InputDecoration(labelText: 'Full Marks', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempStartDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setDialogState(() => tempStartDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.blue.shade300, width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Start: ${_formatDate(tempStartDate)}',
                                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: tempExpireDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2035),
                            );
                            if (picked != null) {
                              setDialogState(() => tempExpireDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.blue.shade300, width: 1.2),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Expire: ${_formatDate(tempExpireDate)}',
                                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: attemptsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Allowed Attempts',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Exam Pricing *',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setDialogState(() => tempIsPaid = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                decoration: BoxDecoration(
                                  color: !tempIsPaid ? Colors.grey.shade200 : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.black45),
                                ),
                                child: Text(
                                  !tempIsPaid ? '✓ Free' : 'Free',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !tempIsPaid ? Colors.black87 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => setDialogState(() => tempIsPaid = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                decoration: BoxDecoration(
                                  color: tempIsPaid ? const Color(0xFFFFD4C4) : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: tempIsPaid ? Colors.deepOrange : Colors.black45),
                                ),
                                child: Row(
                                  children: [
                                    if (tempIsPaid) const Icon(Icons.check, size: 16, color: Colors.black87),
                                    if (tempIsPaid) const SizedBox(width: 4),
                                    Text(
                                      'Paid',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: tempIsPaid ? Colors.black87 : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: priceCtrl,
                          enabled: tempIsPaid,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Exam Price (৳) *',
                            border: const OutlineInputBorder(),
                            filled: !tempIsPaid,
                            fillColor: !tempIsPaid ? Colors.grey.shade100 : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.royalBlue),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      setState(() {
        _examTitle = titleCtrl.text.trim();
        _timeCtrl.text = timeCtrl.text.trim();
        _fullMarkCtrl.text = fullMarkCtrl.text.trim();
        _classCtrl.text = classCtrl.text.trim();
        _subjectCtrl.text = subjectCtrl.text.trim();
        _startDate = tempStartDate;
        _expireDate = tempExpireDate;
        _attemptsCtrl.text = attemptsCtrl.text.trim();
        _isPaid = tempIsPaid;
        _priceCtrl.text = tempIsPaid ? priceCtrl.text.trim() : '0';
      });

      await FirebaseFirestore.instance.collection('exams').doc(widget.examId).update({
        'title': _examTitle,
        'class': _classCtrl.text,
        'subject': _subjectCtrl.text,
        'time': _timeCtrl.text,
        'fullMarks': _fullMarkCtrl.text,
        'startDate': Timestamp.fromDate(_startDate!),
        'expireDate': Timestamp.fromDate(_expireDate!),
        'allowedAttempts': int.tryParse(_attemptsCtrl.text.trim()) ?? 1,
        'isPaid': _isPaid,
        'pricing': _isPaid ? 'paid' : 'free',
        'price': _isPaid ? (num.tryParse(_priceCtrl.text.trim()) ?? 0) : 0,
        'examPrice': _isPaid ? (num.tryParse(_priceCtrl.text.trim()) ?? 0) : 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exam details updated successfully')),
        );
      }
    }

    titleCtrl.dispose();
    timeCtrl.dispose();
    fullMarkCtrl.dispose();
    classCtrl.dispose();
    subjectCtrl.dispose();
    attemptsCtrl.dispose();
    priceCtrl.dispose();
  }

  Future<void> _editItemModal(String docId, Map<String, dynamic> data) async {
    final isPassage = (data['type']?.toString() ?? 'question') == 'passage';
    final editMainCtrl = TextEditingController(text: data['text']?.toString() ?? '');
    final editExpCtrl = TextEditingController(text: data['explanation']?.toString() ?? '');
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
                              onChanged: (v) => setDialogState(() => editCorrect = v ?? 0),
                            ),
                            Expanded(
                              child: TextField(
                                controller: editOpts[i],
                                style: _bn,
                                decoration: InputDecoration(
                                  labelText: 'Option ${String.fromCharCode(65 + i)} *',
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
      final updatedText = isPassage ? editMainCtrl.text.trim() : _cleanLeadingSerial(editMainCtrl.text.trim());

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
      await FirebaseFirestore.instance.collection('exams').doc(widget.examId).update({'questionCount': FieldValue.increment(-1)});
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
    await FirebaseFirestore.instance.collection('exams').doc(widget.examId).update({'published': true});

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

  Future<void> _exportBengaliPdf(
    List<QueryDocumentSnapshot> docs, {
    String? customTitle,
    String? customDate,
  }) async {
    if (docs.isEmpty) return;

    final appName = _appNameCtrl.text.trim();
    final address = _addressCtrl.text.trim().replaceAll('\n', '<br>');
    final examTitle = customTitle?.trim().isNotEmpty == true ? customTitle!.trim() : _examTitle;
    final subject = _subjectCtrl.text.trim().isNotEmpty ? _subjectCtrl.text.trim() : examTitle;
    final className = _classCtrl.text.trim();
    final fullMarkRaw = _fullMarkCtrl.text.trim();
    final timeRaw = _timeCtrl.text.trim();
    final examDateStr = customDate?.trim().isNotEmpty == true
        ? customDate!.trim()
        : _formatDate(_startDate ?? DateTime.now());

    final isExamBangla = isBanglaText(examTitle) || isBanglaText(subject) || isBanglaText(className);

    // Dynamic Labels & Formatted Digits
    final classLabel = isExamBangla ? 'শ্রেণি' : 'Class';
    final subjectLabel = isExamBangla ? 'বিষয়' : 'Subject';
    final markLabel = isExamBangla ? 'পূর্ণমান' : 'Full Marks';
    final timeLabel = isExamBangla ? 'সময়' : 'Time';
    final dateLabel = isExamBangla ? 'তারিখ' : 'Date';

    final fullMarkFormatted = isExamBangla ? toBanglaDigits(fullMarkRaw) : fullMarkRaw;
    final timeFormatted = isExamBangla
        ? '${toBanglaDigits(timeRaw.replaceAll(RegExp(r'[^০-৯0-9]'), ''))} মিনিট'
        : '$timeRaw Minutes';

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
            <div class="passage-tag">${isExamBangla ? 'উদ্দীপক' : 'Passage'}</div>
            <div class="passage-content">$text</div>
          </div>
        ''');
      } else {
        qNum++;
        final isQBangla = isBanglaText(d['text']?.toString() ?? '') || isExamBangla;
        final qNumFormatted = isQBangla ? toBanglaDigits(qNum) : '$qNum';
        final labels = isQBangla ? bnLabels : enLabels;

        final options = rawOptions.map((o) => const HtmlEscape().convert(o)).toList();
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
<html lang="${isExamBangla ? 'bn' : 'en'}">
<head>
  <meta charset="utf-8">
  <title>${const HtmlEscape().convert(examTitle)}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;600;700;800&family=Roboto:wght@400;500;700&display=swap" rel="stylesheet">
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
    .institution-name { font-size: 22px; font-weight: 800; margin: 0; }
    .address { font-size: 11px; color: #333; margin: 3px 0 6px; line-height: 1.4; }
    .exam-title-badge {
      font-size: 16px; font-weight: 800; color: #111; margin: 4px 0;
      letter-spacing: 0.3px;
    }
    .subject-pill {
      display: inline-block; background: #eeeeee;
      padding: 3px 18px; border-radius: 4px; font-weight: 700; font-size: 13.5px;
      margin-top: 4px;
    }
    .meta-row {
      display: flex; justify-content: space-between; font-size: 12.5px;
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
    <div class="exam-title-badge">${const HtmlEscape().convert(examTitle)}</div>
    <div class="subject-pill">${const HtmlEscape().convert(subjectLabel)}: ${const HtmlEscape().convert(subject)}</div>
  </div>
  <div class="meta-row">
    <div>$classLabel: ${const HtmlEscape().convert(className)}</div>
    <div>$dateLabel: ${const HtmlEscape().convert(examDateStr)}</div>
    <div>$timeLabel: ${const HtmlEscape().convert(timeFormatted)}</div>
    <div>$markLabel: ${const HtmlEscape().convert(fullMarkFormatted)}</div>
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
      await printOrExportHtml(fullHtml, examTitle);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _openPrintHeaderDialog(List<QueryDocumentSnapshot> docs) async {
    final titleCtrl = TextEditingController(text: _examTitle);
    final dateCtrl = TextEditingController(text: _formatDate(_startDate ?? DateTime.now()));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exam Header Details', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Exam Title / Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _appNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Institution Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  style: _bn,
                  decoration: const InputDecoration(
                    labelText: 'Address & Contact Info',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _classCtrl,
                        style: _bn,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _subjectCtrl,
                        style: _bn,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _timeCtrl,
                        style: _bn,
                        decoration: const InputDecoration(
                          labelText: 'Time (Minutes)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _fullMarkCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Marks',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Exam Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.royalBlue),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export / Print PDF'),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      await _exportBengaliPdf(
        docs,
        customTitle: titleCtrl.text,
        customDate: dateCtrl.text,
      );
    }

    titleCtrl.dispose();
    dateCtrl.dispose();
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
              alignment: _isPassage ? Alignment.centerLeft : Alignment.centerRight,
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
              alignment: _isPassage ? Alignment.centerRight : Alignment.centerLeft,
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
          _examTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Exam Details',
            icon: const Icon(Icons.edit_note_rounded, size: 24),
            onPressed: _editExamFormDialog,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _qCol.orderBy('order').snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              return IconButton(
                tooltip: 'Export PDF / Print',
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: docs.isEmpty ? null : () => _openPrintHeaderDialog(docs),
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
          const AiPoolStatusCard(),
          const SizedBox(height: 20),
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
                ? 'AI MCQ: enter count, upload notes → new questions & auto header.\n'
                    'Upload MCQ: upload paper → extract questions + form header.\n'
                    'Drag to reorder. Expand a question to see options.'
                : 'Configure API keys in pool above for AI operations.',
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
                                  onChanged: _isPassage ? null : (v) => setState(() => _correct = v ?? 0),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _opts[i],
                                    style: _bn,
                                    decoration: InputDecoration(
                                      labelText: 'Option ${String.fromCharCode(65 + i)} *',
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(
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
                          onPressed: _saving ? null : () => _saveInlineItem(clearAfter: true),
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
                          onPressed: _saving ? null : () => _saveInlineItem(clearAfter: true),
                          child: Text(
                            _saving ? 'Saving…' : (_isPassage ? 'Save Passage' : 'Save question'),
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
                  final isPassage = (d['type']?.toString() ?? 'question') == 'passage';
                  final opts = List<String>.from(d['options'] ?? []);
                  final ci = d['correctIndex'] as int? ?? 0;
                  final text = d['text']?.toString() ?? '';
                  final explanation = d['explanation']?.toString() ?? '';

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

                  qNum++;
                  final displayNum = qNum;
                  final isBangla = isBanglaText(text) || isBanglaText(_examTitle);
                  final badgeLabel = isBangla ? toBanglaDigits(displayNum) : '$displayNum';

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
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: AppTheme.royalBlue.withOpacity(0.12),
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
                              color: isCorrect ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCorrect ? Colors.green : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              '$optLabel. ${opts[optIdx]}${isCorrect ? '  ✓' : ''}',
                              style: _bn.copyWith(
                                fontWeight: isCorrect ? FontWeight.w800 : FontWeight.w500,
                                color: isCorrect ? Colors.green.shade800 : null,
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