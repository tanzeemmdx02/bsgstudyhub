import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class TeacherNotesScreen extends StatefulWidget {
  const TeacherNotesScreen({super.key});

  @override
  State<TeacherNotesScreen> createState() => _TeacherNotesScreenState();
}

class _TeacherNotesScreenState extends State<TeacherNotesScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _bodyFocus = FocusNode();
  
  bool _publishing = false;
  String? _editingId;
  TextAlign _bodyAlign = TextAlign.left;

  bool _isFree = true;

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
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Insert')),
        ],
      ),
    );
    if (ok != true) return;
    final label =
        labelCtrl.text.trim().isEmpty ? 'link' : labelCtrl.text.trim();
    final url =
        urlCtrl.text.trim().isEmpty ? 'https://' : urlCtrl.text.trim();
    _applyWrap('[', ']($url)');
  }

  Future<void> _pickFileBase64() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'pdf'],
      );
      if (file == null) return;

      setState(() => _loadingFile = true);

      final name = file.name;
      final bytes = await file.readAsBytes() as Uint8List;
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
      final looksPdf = bytes.length >= 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46;
      final type = (ext == 'pdf' || looksPdf) ? 'pdf' : 'image';
      final b64 = base64Encode(bytes);

      setState(() {
        _attachmentName = name;
        _attachmentBase64 = b64;
        _attachmentType = type;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
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
        'attachmentType': _attachmentType,
        'attachmentBase64': _attachmentBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      String noteId = '';
      if (_editingId != null) {
        noteId = _editingId!;
        await FirebaseFirestore.instance
            .collection('notes')
            .doc(noteId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        final docRef = await FirebaseFirestore.instance.collection('notes').add(data);
        noteId = docRef.id;

        // Create broad student notification and targeted class notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'title': 'New note Uploaded: ${title.isEmpty ? 'Untitled' : title}',
          'body': 'Targeted Class: $_selectedClass - $_selectedSubjectName',
          'type': 'note',
          'itemId': noteId,
          'targetUserId': 'all_students',
          'classDocId': _matchedClassDocId,
          'class': _selectedClass,
          'subject': _selectedSubjectName,
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
          const SnackBar(content: Text('Note published successfully and notification sent.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e\nUse a file under ~700 KB.'),
            duration: const Duration(seconds: 6),
          ),
        );
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

  void _viewNote(Map<String, dynamic> d) {
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
              if (isPdf &&
                  d['attachmentBase64'] != null &&
                  d['attachmentBase64'].toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        d['attachmentName']?.toString() ?? 'PDF attached',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
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

  Future<void> _archiveNote(DocumentReference ref) async {
    await ref.update({'archived': true});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note archived.')),
      );
    }
  }

  Future<void> _deleteNote(DocumentReference ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
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
              _attachmentName ?? (isPdf ? 'PDF' : 'Image'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _editingId != null ? 'Update & Publish' : 'Classify & Publish',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
        const SizedBox(height: 14),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('classes').snapshots(),
          builder: (context, snap) {
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Text('No classes found in Daily Attendance.', style: TextStyle(fontSize: 12, color: Colors.red));
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

            if (_matchedClassDocId != null && !matchingClassDocs.any((d) => d.id == _matchedClassDocId)) {
              _matchedClassDocId = null;
              _selectedSubjectName = null;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                DropdownButtonFormField<String>(
                  value: _matchedClassDocId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Subject *', border: OutlineInputBorder(), isDense: true),
                  items: matchingClassDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final subj = data['subject']?.toString().trim() ?? 'Subject';
                    return DropdownMenuItem<String>(value: doc.id, child: Text(subj));
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
              ],
            );
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
            _editingId != null ? 'Update' : 'Publish Note',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
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
                    if (_editingId != null)
                      Row(
                        children: [
                          Chip(
                            label: const Text('Editing'),
                            backgroundColor: AppTheme.royalBlue.withOpacity(0.12),
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
                      style: const TextStyle(fontSize: 28, height: 1.3),
                      decoration: const InputDecoration(
                        hintText: 'Add title',
                        hintStyle: TextStyle(fontSize: 28, color: Colors.black38),
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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                          hintText: 'Write your note…',
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
                        _loadingFile ? 'Loading…' : 'Attach image / PDF (max ~700 KB)',
                      ),
                    ),
                    _attachmentPreviewChip(),
                    const SizedBox(height: 28),
                    const Text(
                      'Published Notes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
          .collection('notes')
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
          return const Text('No notes yet.', style: TextStyle(color: Colors.black45));
        }
        return Column(
          children: docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final isPdf = d['attachmentType'] == 'pdf';
            final img = _decodeImage(d);
            final targetClass = d['class'];
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
                    leading: isPdf
                        ? const Icon(Icons.picture_as_pdf, color: Colors.red)
                        : (img != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.memory(
                                  img,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.note_alt_outlined,
                                    color: AppTheme.royalBlue,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.note_alt_outlined,
                                color: AppTheme.royalBlue,
                              )),
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
                            '[Target: $targetClass • ${d['group'] ?? ''} • ${d['subDepartment'] ?? ''} • ${d['subject'] ?? ''}]',
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
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                    child: Wrap(
                      children: [
                        TextButton(
                          onPressed: () => _viewNote(d),
                          child: const Text('View'),
                        ),
                        TextButton(
                          onPressed: () => _loadForEdit(doc.id, d),
                          child: const Text('Edit'),
                        ),
                        TextButton(
                          onPressed: () => _archiveNote(doc.reference),
                          child: const Text('Archive'),
                        ),
                        TextButton(
                          onPressed: () => _deleteNote(doc.reference),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  Widget _tb(String label, VoidCallback onTap,
      {bool bold = false, bool italic = false}) {
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