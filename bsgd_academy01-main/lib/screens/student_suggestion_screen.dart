import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import '../utils/html_pdf_printer.dart';

class StudentSuggestionScreen extends StatelessWidget {
  const StudentSuggestionScreen({super.key});

  Uint8List? _imageBytes(Map<String, dynamic> d) {
    return decodeImageBase64(
      d['attachmentBase64']?.toString(),
      d['attachmentType']?.toString(),
    );
  }

  Future<void> _openSuggestionPdfReader(String title, Map<String, dynamic> d) async {
    final body = d['body']?.toString() ?? d['description']?.toString() ?? '';
    final attachmentBase64 = d['attachmentBase64']?.toString();
    final attachmentType = d['attachmentType']?.toString();
    final attachmentName = d['attachmentName']?.toString();
    final subjectName = d['subject']?.toString() ?? '';
    final className = d['class']?.toString() ?? '';
    final groupName = d['group']?.toString() ?? '';
    final fileName = attachmentName != null && attachmentName.toLowerCase().endsWith('.pdf')
        ? attachmentName
        : '${title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_')}.pdf';

    // 1) Real PDF attachment check
    if (attachmentType == 'pdf' &&
        attachmentBase64 != null &&
        attachmentBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(attachmentBase64);
        final isRealPdf = bytes.length >= 4 &&
            bytes[0] == 0x25 && // %
            bytes[1] == 0x50 && // P
            bytes[2] == 0x44 && // D
            bytes[3] == 0x46;   // F
        if (isRealPdf) {
          await downloadFile(bytes, fileName, 'application/pdf');
          return;
        }
      } catch (_) {}
    }

    // 2) Build rich HTML template with Noto Sans Bengali support for mobile/web export
    final formattedBody = const HtmlEscape().convert(body).replaceAll('\n', '<br>');
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
  <div class="content">$formattedBody</div>
</body>
</html>
''';

    try {
      await printOrExportHtml(htmlContent, title);
    } catch (e) {
      throw Exception('PDF generation failed: $e');
    }
  }

  void _viewSuggestionDetails(BuildContext context, Map<String, dynamic> d) {
    final title = d['title']?.toString() ?? 'Suggestion';
    final body = d['body']?.toString() ?? d['description']?.toString() ?? '';
    final targetClass = d['class'];
    final subject = d['subject'];
    final img = _imageBytes(d);
    final isFree = d['isFree'] ?? true;
    final price = d['price'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
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
                        isFree ? 'FREE PDF' : 'PRICE: ৳$price (PDF)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isFree ? Colors.green.shade800 : Colors.deepOrange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (targetClass != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.royalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Class: $targetClass • Dept: ${d['group'] ?? 'General'} • Section: ${d['subDepartment'] ?? 'General'} • Subject: ${subject ?? 'General'}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.royalBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SelectableText(
                  body,
                  style: const TextStyle(fontSize: 14.5, height: 1.5),
                ),
                if (img != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(img, fit: BoxFit.contain),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  onPressed: () => _openSuggestionPdfReader(title, d),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download / Open PDF Document', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
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

  Future<void> _hideSuggestion(
      BuildContext context, String sugId, String title) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Suggestion'),
        content: Text('Are you sure you want to remove "$title" from your saved suggestions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      await userRef.collection('saved_suggestions').doc(sugId).delete();

      await userRef.set({
        'hidden_suggestions': FieldValue.arrayUnion([sugId])
      }, SetOptions(merge: true));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed "$title" from your dashboard.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove: $e')),
      );
    }
  }

  bool _matchesStudentProfile(Map<String, dynamic> suggestionData, Map<String, dynamic>? studentData) {
    if (studentData == null) return false;

    final sugClass = suggestionData['class']?.toString().trim();
    final sugGroup = suggestionData['group']?.toString().trim();
    final sugSubDept = suggestionData['subDepartment']?.toString().trim();
    final sugSubject = suggestionData['subject']?.toString().trim();

    final studentClass = studentData['class']?.toString().trim();
    final studentGroup = studentData['group']?.toString().trim();
    final studentSubDept = studentData['subDepartment']?.toString().trim();
    final studentSubject = studentData['subject']?.toString().trim();

    if (sugClass != null && sugClass.isNotEmpty && sugClass != 'General' && sugClass != studentClass) {
      return false;
    }
    if (sugGroup != null && sugGroup.isNotEmpty && sugGroup != 'General' && sugGroup != studentGroup) {
      return false;
    }
    if (sugSubDept != null && sugSubDept.isNotEmpty && sugSubDept != 'General' && sugSubDept != studentSubDept) {
      return false;
    }
    if (sugSubject != null && sugSubject.isNotEmpty && sugSubject != 'General' && sugSubject != studentSubject) {
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Saved Suggestions')),
        body: const Center(
          child: Text('Please log in to view your saved suggestions.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Saved Suggestions'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>?;
          final bool autoEnrollFree = userData?['autoEnrollFree'] == true;
          final hiddenSuggestions = List<String>.from(userData?['hidden_suggestions'] ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('saved_suggestions')
                .snapshots(),
            builder: (context, savedSnap) {
              if (savedSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final savedDocs = savedSnap.data?.docs ?? [];
              final savedIds = savedDocs.map((d) => d.id).toSet();

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('suggestions')
                    .snapshots(),
                builder: (context, sugSnap) {
                  if (sugSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allSuggestions = List<QueryDocumentSnapshot>.from(sugSnap.data?.docs ?? []);
                  
                  allSuggestions.sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime);
                  });
                  
                  final filtered = allSuggestions.where((doc) {
                    if (hiddenSuggestions.contains(doc.id)) return false;
                    final d = doc.data() as Map<String, dynamic>;
                    final isFree = d['isFree'] ?? true;
                    final matches = _matchesStudentProfile(d, userData);
                    return savedIds.contains(doc.id) || (autoEnrollFree && isFree && matches);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 64,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No saved suggestions found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final doc = filtered[i];
                      final d = doc.data() as Map<String, dynamic>;
                      final title = d['title']?.toString() ?? 'Suggestion';
                      final desc = d['description']?.toString() ?? d['body']?.toString() ?? '';
                      final targetClass = d['class'];

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _viewSuggestionDetails(context, d),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.red,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (targetClass != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '$targetClass • ${d['group'] ?? ''} • ${d['subDepartment'] ?? ''} • ${d['subject'] ?? 'General'}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.royalBlue,
                                          ),
                                        ),
                                      ],
                                      if (desc.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          desc,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.redAccent),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _hideSuggestion(context, doc.id, title),
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text(
                                    'Remove',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}