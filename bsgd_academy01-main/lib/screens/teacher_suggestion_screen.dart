import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/ai_mcq_service.dart';
import '../services/ai_suggestion_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import '../utils/html_pdf_printer.dart';
import 'teacher_ai_suggestions_screen.dart';

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

class TeacherSuggestionScreen extends StatefulWidget {
  const TeacherSuggestionScreen({super.key});

  @override
  State<TeacherSuggestionScreen> createState() =>
      _TeacherSuggestionScreenState();
}

class _TeacherSuggestionScreenState extends State<TeacherSuggestionScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _bodyFocus = FocusNode();
  bool _publishing = false;
  bool _generatingAi = false;
  String? _editingId;
  TextAlign _bodyAlign = TextAlign.left;

  // Pricing Fields
  bool _isFree = true;

  // Academic Classification Fields
  String? _selectedClass;
  String? _selectedGroup;
  String? _selectedSubDept;
  String? _matchedClassDocId;
  String? _selectedSubjectName;

  String? _attachmentName;
  String? _attachmentBase64;
  String? _attachmentType;
  bool _loadingFile = false;

  static const int _maxBytes = 700 * 1024;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _priceCtrl.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _applyWrap(String left, String right) {
    _bodyFocus.requestFocus();
    final text = _bodyCtrl.text;
    var sel = _bodyCtrl.selection;
    if (!sel.isValid) {
      sel = TextSelection.collapsed(offset: text.length);
    }
    final start = sel.start;
    final end = sel.end;
    final selected = text.substring(start, end);
    final middle = selected.isEmpty ? 'text' : selected;
    final inserted = '$left$middle$right';
    final newText = text.replaceRange(start, end, inserted);
    final midStart = start + left.length;
    final midEnd = midStart + middle.length;
    _bodyCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection(baseOffset: midStart, extentOffset: midEnd),
    );
  }

  String _selectedText() {
    final sel = _bodyCtrl.selection;
    if (!sel.isValid || sel.start == sel.end) return '';
    return _bodyCtrl.text.substring(sel.start, sel.end);
  }

  Future<void> _insertUrl() async {
    _bodyFocus.requestFocus();
    final labelCtrl = TextEditingController(
      text: _selectedText().isEmpty ? 'link text' : _selectedText(),
    );
    final urlCtrl = TextEditingController(text: 'https://');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Insert link'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Insert'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final label =
        labelCtrl.text.trim().isEmpty ? 'link' : labelCtrl.text.trim();
    final url = urlCtrl.text.trim().isEmpty ? 'https://' : urlCtrl.text.trim();
    _applyWrap('[', ']($url)');
  }

  Future<void> _pickFileBase64() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
      );
      if (pickedFiles.isEmpty) return;
      final file = pickedFiles.first;

      setState(() => _loadingFile = true);
      final name = file.name;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      if (bytes.length > _maxBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'File too large (${(bytes.length / 1024).toStringAsFixed(0)} KB). Max ~700 KB.',
              ),
            ),
          );
        }
        return;
      }

      final ext = name.split('.').last.toLowerCase();
      final looksPdf =
          bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;
      final type = (ext == 'pdf' || looksPdf) ? 'pdf' : 'image';

      setState(() {
        _attachmentName = name;
        _attachmentBase64 = base64Encode(bytes);
        _attachmentType = type;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attached $type: $name (${(bytes.length / 1024).toStringAsFixed(0)} KB)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loadingFile = false);
    }
  }

  void _clearAttachment() {
    setState(() {
      _attachmentName = null;
      _attachmentBase64 = null;
      _attachmentType = null;
    });
  }

  void _autoMatchClassification(String hint) {
    if (hint.isEmpty) return;
    FirebaseFirestore.instance.collection('classes').get().then((snap) {
      if (!mounted || snap.docs.isEmpty) return;
      final lowerHint = hint.toLowerCase();
      for (final doc in snap.docs) {
        final data = doc.data();
        final subj = (data['subject'] ?? '').toString().trim().toLowerCase();
        final cls = (data['name'] ?? '').toString().trim().toLowerCase();
        if ((subj.isNotEmpty && lowerHint.contains(subj)) ||
            (cls.isNotEmpty && lowerHint.contains(cls))) {
          setState(() {
            _selectedClass = data['name']?.toString().trim();
            _selectedGroup = data['department']?.toString().trim();
            _selectedSubDept = data['subDepartment']?.toString().trim() ?? 'General';
            _matchedClassDocId = doc.id;
            _selectedSubjectName = data['subject']?.toString().trim();
          });
          break;
        }
      }
    });
  }

  Future<void> _generateAiSuggestionWithUpload(String type) async {
    if (!AiMcqService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Need GEMINI_API_KEY.\n'
            'Add keys via the AI Engine & API Pool card above.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
      );
      if (pickedFiles.isEmpty) return;
      final file = pickedFiles.first;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      final name = file.name;
      final ext = name.split('.').last.toLowerCase();
      final looksPdf =
          bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;
      final mimeType = (ext == 'pdf' || looksPdf) ? 'application/pdf' : 'image/jpeg';

      setState(() => _generatingAi = true);

      if (type == 'CQ') {
        final cqData = await AiSuggestionService.generateCq(bytes: bytes, mimeType: mimeType);
        
        final sb = StringBuffer();
        sb.writeln('উদ্দীপক: ${cqData.passage}\n');
        for (var item in cqData.items) {
          sb.writeln('(${item.label}) ${item.question}');
          sb.writeln('সংক্ষিপ্ত উত্তর: ${item.shortAnswer}');
          sb.writeln('বিশদ উত্তর: ${item.detailedAnswer}\n');
        }

        setState(() {
          _titleCtrl.text = cqData.title;
          _bodyCtrl.text = sb.toString().trim();
        });

        _autoMatchClassification('${cqData.title} ${cqData.passage}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI successfully generated CQ suggestion from file! Classification matched.')),
          );
        }
      } else {
        final shortData = await AiSuggestionService.generateShort(bytes: bytes, mimeType: mimeType);

        final sb = StringBuffer();
        sb.writeln('বিষয়: ${shortData.subject}\n');
        sb.writeln('মূল পয়েন্টসমূহ:');
        for (var kp in shortData.keyPoints) {
          sb.writeln('• $kp');
        }
        sb.writeln('\nসংক্ষিপ্ত প্রশ্নাবলী:');
        for (var sq in shortData.shortQuestions) {
          sb.writeln('প্রশ্ন: ${sq['q']}');
          sb.writeln('উত্তর: ${sq['a']}\n');
        }

        setState(() {
          _titleCtrl.text = shortData.title;
          _bodyCtrl.text = sb.toString().trim();
        });

        _autoMatchClassification('${shortData.title} ${shortData.subject}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('AI successfully generated Short suggestion from file! Classification matched.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI Generation failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingAi = false);
    }
  }

  Future<void> _publish() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty && _attachmentBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a title, content, or file.')),
      );
      return;
    }

    if (_selectedClass == null ||
        _selectedGroup == null ||
        _selectedSubDept == null ||
        _matchedClassDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please classify target Class, Department, Sub-Department, and Subject.'),
        ),
      );
      return;
    }

    double parsedPrice = 0.0;
    if (!_isFree) {
      parsedPrice = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
      if (parsedPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid price greater than 0.')),
        );
        return;
      }
    }

    setState(() => _publishing = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final data = <String, dynamic>{
        'title': title.isEmpty ? 'Untitled' : title,
        'body': body,
        'teacherId': uid,
        'teacherName': AuthService().currentUserName,
        'textAlign': _bodyAlign.name,
        'archived': false,
        'isFree': _isFree,
        'price': _isFree ? 0.0 : parsedPrice,
        'class': _selectedClass,
        'group': _selectedGroup,
        'department': _selectedGroup,
        'subDepartment': _selectedSubDept,
        'classDocId': _matchedClassDocId,
        'subject': _selectedSubjectName,
        'attachmentName': _attachmentName,
        'attachmentType': _attachmentType ?? 'pdf',
        'attachmentBase64': _attachmentBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String suggestionId = '';
      if (_editingId != null) {
        suggestionId = _editingId!;
        await FirebaseFirestore.instance
            .collection('suggestions')
            .doc(suggestionId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        final suggestionRef = await FirebaseFirestore.instance.collection('suggestions').add(data);
        suggestionId = suggestionRef.id;

        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New suggestion Uploaded (PDF Ready)',
          'body': title.isEmpty ? 'Untitled' : title,
          'type': 'suggestion',
          'itemId': suggestionId,
          'targetUserId': 'all',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _titleCtrl.clear();
      _bodyCtrl.clear();
      _priceCtrl.clear();
      _clearAttachment();
      setState(() {
        _editingId = null;
        _bodyAlign = TextAlign.left;
        _isFree = true;
        _selectedClass = null;
        _selectedGroup = null;
        _selectedSubDept = null;
        _matchedClassDocId = null;
        _selectedSubjectName = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suggestion saved and classified successfully. Use Download PDF to get a printable file.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _loadForEdit(String id, Map<String, dynamic> d) {
    _titleCtrl.text = d['title']?.toString() ?? '';
    _bodyCtrl.text = d['body']?.toString() ?? '';
    final free = d['isFree'] ?? true;
    _isFree = free;
    _priceCtrl.text = free ? '' : (d['price']?.toString() ?? '');

    setState(() {
      _editingId = id;
      _selectedClass = d['class']?.toString();
      _selectedGroup = d['group']?.toString() ?? d['department']?.toString();
      _selectedSubDept = d['subDepartment']?.toString();
      _matchedClassDocId = d['classDocId']?.toString();
      _selectedSubjectName = d['subject']?.toString();
      _attachmentName = d['attachmentName']?.toString();
      _attachmentBase64 = d['attachmentBase64']?.toString();
      _attachmentType = d['attachmentType']?.toString();
      final a = d['textAlign']?.toString();
      _bodyAlign = a == 'justify' ? TextAlign.justify : TextAlign.left;
    });
  }

  Uint8List? _decodeImage(Map<String, dynamic> d) {
    if (d['attachmentType'] == 'pdf') return null;
    final b64 = d['attachmentBase64']?.toString();
    if (b64 == null || b64.isEmpty) return null;
    try {
      final bytes = base64Decode(b64);
      if (bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46) {
        return null;
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  void _viewItem(Map<String, dynamic> d) {
    final isPdf = d['attachmentType'] == 'pdf';
    final img = _decodeImage(d);
    final isFree = d['isFree'] ?? true;
    final price = d['price'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d['title']?.toString() ?? 'Untitled'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isFree ? Colors.green : Colors.deepOrange).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isFree ? 'FREE' : 'PRICE: ৳$price',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isFree ? Colors.green.shade800 : Colors.deepOrange.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (d['class'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.royalBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Class: ${d['class']} • Dept: ${d['group'] ?? 'General'} • Section: ${d['subDepartment'] ?? 'General'} • Subject: ${d['subject'] ?? 'General'}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.royalBlue),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SelectableText(
                d['body']?.toString() ?? '',
                style: const TextStyle(height: 1.5, fontSize: 15),
              ),
              if (img != null) ...[
                const SizedBox(height: 16),
                Image.memory(img, fit: BoxFit.contain),
              ],
              if (isPdf) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(d['attachmentName']?.toString() ?? 'PDF Suggestion')),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveItem(DocumentReference ref) async {
    await ref.update({'archived': true});
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Archived.')));
    }
  }

  Future<void> _deleteItem(DocumentReference ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete suggestion?'),
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
    if (ok == true) await ref.delete();
  }

  Widget _attachmentPreviewChip() {
    if (_attachmentBase64 == null) return const SizedBox.shrink();
    final isPdf = _attachmentType == 'pdf';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          if (!isPdf)
            Builder(
              builder: (_) {
                try {
                  final bytes = base64Decode(_attachmentBase64!);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      bytes,
                      height: 72,
                      width: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 40),
                    ),
                  );
                } catch (_) {
                  return const Icon(Icons.broken_image);
                }
              },
            )
          else
            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _attachmentName ?? (isPdf ? 'PDF Ready' : 'Image'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _clearAttachment,
          ),
        ],
      ),
    );
  }

  Widget _buildPublishSidebar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            'No classes found in Daily Attendance module. Please add a class first.',
            style: TextStyle(fontSize: 12, color: Colors.red),
          );
        }

        final List<String> classesList = docs
            .map((d) => (d.data() as Map<String, dynamic>)['name']?.toString().trim() ?? '')
            .where((n) => n.isNotEmpty)
            .toSet()
            .toList();

        if (_selectedClass != null && !classesList.contains(_selectedClass)) {
          _selectedClass = null;
        }

        List<String> groupsList = [];
        if (_selectedClass != null) {
          groupsList = docs
              .where((d) => (d.data() as Map<String, dynamic>)['name']?.toString().trim() == _selectedClass)
              .map((d) => (d.data() as Map<String, dynamic>)['department']?.toString().trim() ?? '')
              .where((g) => g.isNotEmpty)
              .toSet()
              .toList();
        }

        if (_selectedGroup != null && !groupsList.contains(_selectedGroup)) {
          _selectedGroup = null;
        }

        List<String> subDeptsList = [];
        if (_selectedClass != null && _selectedGroup != null) {
          subDeptsList = docs
              .where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['name']?.toString().trim() == _selectedClass &&
                    data['department']?.toString().trim() == _selectedGroup;
              })
              .map((d) => (d.data() as Map<String, dynamic>)['subDepartment']?.toString().trim() ?? 'General')
              .where((sd) => sd.isNotEmpty)
              .toSet()
              .toList();
        }

        if (_selectedSubDept != null && !subDeptsList.contains(_selectedSubDept)) {
          _selectedSubDept = null;
        }

        List<QueryDocumentSnapshot> matchingClassDocs = [];
        if (_selectedClass != null && _selectedGroup != null && _selectedSubDept != null) {
          matchingClassDocs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final sd = data['subDepartment']?.toString().trim() ?? 'General';
            return data['name']?.toString().trim() == _selectedClass &&
                data['department']?.toString().trim() == _selectedGroup &&
                sd == _selectedSubDept;
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Publish Options',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pricing Options *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Free'),
                          selected: _isFree,
                          onSelected: (val) => setState(() => _isFree = true),
                          selectedColor: Colors.green.shade100,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Paid'),
                          selected: !_isFree,
                          onSelected: (val) => setState(() => _isFree = false),
                          selectedColor: Colors.deepOrange.shade100,
                        ),
                      ),
                    ],
                  ),
                  if (!_isFree) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      decoration: const InputDecoration(
                        labelText: 'Price (৳) *',
                        hintText: 'e.g. 150',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Class Dropdown
            DropdownButtonFormField<String>(
              value: _selectedClass,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Class *', border: OutlineInputBorder(), isDense: true),
              items: classesList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedClass = val;
                  _selectedGroup = null;
                  _selectedSubDept = null;
                  _matchedClassDocId = null;
                  _selectedSubjectName = null;
                });
              },
            ),
            const SizedBox(height: 10),

            // Department Dropdown
            DropdownButtonFormField<String>(
              value: _selectedGroup,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Department / Group *', border: OutlineInputBorder(), isDense: true),
              items: groupsList.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: _selectedClass == null ? null : (val) {
                setState(() {
                  _selectedGroup = val;
                  _selectedSubDept = null;
                  _matchedClassDocId = null;
                  _selectedSubjectName = null;
                });
              },
            ),
            const SizedBox(height: 10),

            // Sub-Department Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubDept,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Sub-Department / Section *', border: OutlineInputBorder(), isDense: true),
              items: subDeptsList.map((sd) => DropdownMenuItem(value: sd, child: Text(sd))).toList(),
              onChanged: _selectedGroup == null ? null : (val) {
                setState(() {
                  _selectedSubDept = val;
                  _matchedClassDocId = null;
                  _selectedSubjectName = null;
                });
              },
            ),
            const SizedBox(height: 10),

            // Subject Dropdown
            DropdownButtonFormField<String>(
              value: _matchedClassDocId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder(), isDense: true),
              items: matchingClassDocs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final subj = data['subject']?.toString().trim() ?? 'Subject';
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(subj),
                );
              }).toList(),
              onChanged: _selectedSubDept == null ? null : (docId) {
                if (docId != null) {
                  final matchDoc = matchingClassDocs.firstWhere((d) => d.id == docId);
                  final data = matchDoc.data() as Map<String, dynamic>;
                  setState(() {
                    _matchedClassDocId = docId;
                    _selectedSubjectName = data['subject']?.toString().trim();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _publishing ? null : _publish,
              child: Text(
                _editingId != null ? 'Update & PDF Compile' : 'Publish PDF Suggestion',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 900;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AiPoolStatusCard(),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Faculty Suggestions (PDF Auto-Compiled)',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Published suggestions automatically convert to professional PDFs for students.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.amber.shade900,
                                side: BorderSide(color: Colors.amber.shade700),
                              ),
                              onPressed: _generatingAi ? null : () => _generateAiSuggestionWithUpload('CQ'),
                              icon: const Icon(Icons.psychology, size: 18),
                              label: const Text('Upload for CQ', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.royalBlue,
                              ),
                              onPressed: _generatingAi ? null : () => _generateAiSuggestionWithUpload('Short'),
                              icon: const Icon(Icons.auto_awesome, size: 18),
                              label: const Text('Upload for Short', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_generatingAi) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 4),
                      const Text('AI is analyzing study document and generating suggestion...', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ],
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    if (_editingId != null)
                      Row(
                        children: [
                          Chip(
                            label: const Text('Editing'),
                            backgroundColor: AppTheme.academicGold.withOpacity(0.25),
                          ),
                          TextButton(
                            onPressed: () {
                              _titleCtrl.clear();
                              _bodyCtrl.clear();
                              _priceCtrl.clear();
                              _clearAttachment();
                              setState(() => _editingId = null);
                            },
                            child: const Text('Cancel edit'),
                          ),
                        ],
                      ),
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(fontSize: 26, height: 1.3),
                      decoration: const InputDecoration(
                        hintText: 'Add title',
                        hintStyle: TextStyle(
                          fontSize: 26,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    if (!wide) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _buildPublishSidebar(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _tb('B', () => _applyWrap('**', '**'), bold: true),
                            _tb('I', () => _applyWrap('_', '_'), italic: true),
                            _tb('J', () {
                              setState(() {
                                _bodyAlign = _bodyAlign == TextAlign.justify
                                    ? TextAlign.left
                                    : TextAlign.justify;
                              });
                            }),
                            _sep(),
                            _tbIcon(Icons.link, _insertUrl),
                            _tbIcon(Icons.attach_file, _pickFileBase64),
                          ],
                        ),
                      ),
                    ),
                    if (_loadingFile) const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(minHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextField(
                        controller: _bodyCtrl,
                        focusNode: _bodyFocus,
                        maxLines: null,
                        minLines: 8,
                        textAlign: _bodyAlign,
                        style: const TextStyle(fontSize: 15, height: 1.55),
                        decoration: const InputDecoration(
                          hintText: 'Write or generate your suggestion… will be compiled into a PDF document upon publish.',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadingFile ? null : _pickFileBase64,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text(
                        _loadingFile
                            ? 'Loading…'
                            : 'Attach reference image / PDF (max ~700 KB)',
                      ),
                    ),
                    _attachmentPreviewChip(),
                    const SizedBox(height: 28),
                    const Text(
                      'Published PDF Suggestions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _publishedList(),
                  ],
                ),
              ),
            ),
            if (wide)
              Container(
                width: 320,
                margin: const EdgeInsets.only(top: 16, right: 16),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: SingleChildScrollView(child: _buildPublishSidebar()),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _publishedList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('suggestions')
          .orderBy('createdAt', descending: true)
          .limit(40)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = (snap.data?.docs ?? []).where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return d['archived'] != true;
        }).toList();
        if (docs.isEmpty) {
          return const Text(
            'No suggestions published yet.',
            style: TextStyle(color: Colors.black45),
          );
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final targetClass = d['class'];
            final targetSubject = d['subject'];
            final isFree = d['isFree'] ?? true;
            final price = d['price'] ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            d['title'] ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isFree ? Colors.green : Colors.deepOrange).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isFree ? 'FREE' : '৳$price',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isFree ? Colors.green.shade800 : Colors.deepOrange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (targetClass != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '[Target: $targetClass • ${d['group'] ?? ''} • ${d['subDepartment'] ?? ''} • ${targetSubject ?? ''}]',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.royalBlue),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          d['body'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: const Text(
                      'PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      bottom: 8,
                    ),
                    child: Wrap(
                      children: [
                        TextButton(
                          onPressed: () async {
                            try {
                              final title = d['title']?.toString() ?? 'Suggestion';
                              final body = d['body']?.toString() ?? '';
                              final subjectName = d['subject']?.toString() ?? '';
                              final className = d['class']?.toString() ?? '';
                              final groupName = d['group']?.toString() ?? '';
                              final attachmentB64 = d['attachmentBase64']?.toString();
                              final attachmentType = d['attachmentType']?.toString();
                              final attachmentName = d['attachmentName']?.toString() ?? '$title.pdf';

                              // 1) If a REAL PDF was attached (bytes start with %PDF), download it directly
                              if (attachmentType == 'pdf' &&
                                  attachmentB64 != null &&
                                  attachmentB64.isNotEmpty) {
                                try {
                                  final bytes = base64Decode(attachmentB64);
                                  final isRealPdf = bytes.length >= 4 &&
                                      bytes[0] == 0x25 && // %
                                      bytes[1] == 0x50 && // P
                                      bytes[2] == 0x44 && // D
                                      bytes[3] == 0x46;   // F
                                  if (isRealPdf) {
                                    await downloadBase64File(
                                      context: context,
                                      base64Data: attachmentB64,
                                      fileName: attachmentName.endsWith('.pdf')
                                          ? attachmentName
                                          : '$attachmentName.pdf',
                                      type: 'pdf',
                                    );
                                    return;
                                  }
                                } catch (_) {
                                  // Fall through to HTML → PDF path
                                }
                              }

                              // 2) Build clean HTML and let printOrExportHtml produce a proper PDF
                              final formattedBodyHtml =
                                  const HtmlEscape().convert(body).replaceAll('\n', '<br>');

                              final htmlContent = '''
<!DOCTYPE html>
<html lang="bn">
<head>
  <meta charset="utf-8">
  <title>${const HtmlEscape().convert(title)}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    @page { size: A4 portrait; margin: 18mm; }
    body {
      font-family: 'Noto Sans Bengali', 'Noto Sans', Arial, sans-serif;
      color: #111;
      line-height: 1.65;
      font-size: 14px;
      background: #fff;
      margin: 0;
      padding: 0;
    }
    .header {
      text-align: center;
      border-bottom: 2px solid #1a365d;
      padding-bottom: 12px;
      margin-bottom: 20px;
    }
    .title {
      font-size: 22px;
      font-weight: 800;
      color: #1a365d;
      margin: 0 0 6px 0;
    }
    .meta {
      font-size: 12px;
      color: #555;
      font-weight: 700;
    }
    .content {
      padding: 8px 0;
      word-break: break-word;
      white-space: pre-wrap;
    }
  </style>
</head>
<body>
  <div class="header">
    <div class="title">${const HtmlEscape().convert(title)}</div>
    <div class="meta">Subject: $subjectName | Class: $className | Dept: $groupName</div>
  </div>
  <div class="content">$formattedBodyHtml</div>
</body>
</html>
''';

                              await printOrExportHtml(htmlContent, title);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Download failed: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Download PDF'),
                        ),
                        TextButton(
                          onPressed: () => _viewItem(d),
                          child: const Text('View'),
                        ),
                        TextButton(
                          onPressed: () => _loadForEdit(doc.id, d),
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed: () => _archiveItem(doc.reference),
                          child: const Text('Archive'),
                        ),
                        TextButton(
                          onPressed: () => _deleteItem(doc.reference),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _tb(
    String label,
    VoidCallback onTap, {
    bool bold = false,
    bool italic = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ),
    );
  }

  Widget _tbIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 18),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
    );
  }

  Widget _sep() => Container(
        width: 1,
        height: 18,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.grey.shade300,
      );
}