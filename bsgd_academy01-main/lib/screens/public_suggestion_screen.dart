import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/student_login_screen.dart';
import '../services/auth_service.dart';
import '../services/bkash_payment_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import '../utils/html_pdf_printer.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/bkash_payment_modal.dart';

class PublicSuggestionScreen extends StatefulWidget {
  const PublicSuggestionScreen({super.key});

  @override
  State<PublicSuggestionScreen> createState() => _PublicSuggestionScreenState();
}

class _PublicSuggestionScreenState extends State<PublicSuggestionScreen> {
  bool _autoEnrollFree = true;

  @override
  void initState() {
    super.initState();
    _loadAutoEnrollPreference();
  }

  Future<void> _loadAutoEnrollPreference() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      if (data.containsKey('autoEnrollFree')) {
        setState(() {
          _autoEnrollFree = data['autoEnrollFree'] == true;
        });
      }
    }
  }

  Future<void> _toggleAutoEnroll(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _autoEnrollFree = value);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'autoEnrollFree': value,
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Auto-enroll enabled: Matching free suggestions will automatically appear in your dashboard.'
                : 'Auto-enroll disabled.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  int _cols(double w) {
    if (w < 600) return 1;
    if (w < 900) return 2;
    if (w < 1200) return 3;
    return 4;
  }

  Uint8List? _imageBytes(Map<String, dynamic> d) {
    return decodeImageBase64(
      d['attachmentBase64']?.toString(),
      d['attachmentType']?.toString(),
    );
  }

  Future<void> _addToDashboard(String sugId, String sugTitle) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showLoginPrompt(sugTitle);
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_suggestions')
        .doc(sugId)
        .set({
      'suggestionId': sugId,
      'title': sugTitle,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$sugTitle" added to your dashboard!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showLoginPrompt(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.deepOrange),
            SizedBox(width: 8),
            Text('Login Required'),
          ],
        ),
        content: Text('You must be logged in to save "$title" to your dashboard.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSuggestionPdfReader(String title, Map<String, dynamic> d) async {
    final body = d['body']?.toString() ?? '';
    final attachmentBase64 = d['attachmentBase64']?.toString();
    final attachmentType = d['attachmentType']?.toString();
    final attachmentName = d['attachmentName']?.toString();
    final subjectName = d['subject']?.toString() ?? '';
    final className = d['class']?.toString() ?? '';
    final groupName = d['group']?.toString() ?? '';
    final fileName = attachmentName != null && attachmentName.toLowerCase().endsWith('.pdf')
        ? attachmentName
        : '${title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_')}.pdf';

    // 1) Real PDF attachment (bytes start with %PDF) → download directly
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Downloading "$fileName"...')),
            );
          }
          return;
        }
      } catch (_) {
        // Fall through to HTML → print/PDF path
      }
    }

    // 2) Build clean HTML with Bengali font support and use printOrExportHtml
    //    (web: browser Save as PDF; mobile: Printing.convertHtml → real PDF)
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening print dialog — choose "Save as PDF" to download.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _viewSuggestionDetails(BuildContext context, String docId, Map<String, dynamic> d) async {
    final user = FirebaseAuth.instance.currentUser;
    final isFree = d['isFree'] ?? true;
    final price = d['price'] ?? 0;
    final title = d['title']?.toString() ?? 'Suggestion';

    if (!isFree && price > 0) {
      if (user == null) {
        _showLoginPrompt(title);
        return;
      }
      final unlocked = await BkashPaymentService.hasPurchasedItem(docId);
      if (!unlocked) {
        if (!context.mounted) return;
        final paid = await BkashPaymentModal.show(
          context,
          itemId: docId,
          itemType: 'suggestion',
          itemTitle: title,
          price: (price as num).toDouble(),
        );
        if (paid != true) return;
      }
    }

    final body = d['body']?.toString() ?? d['description']?.toString() ?? '';
    final targetClass = d['class'];
    final subject = d['subject'];
    final img = _imageBytes(d);

    if (!context.mounted) return;

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
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _addToDashboard(docId, title);
            },
            icon: const Icon(Icons.add_to_photos_outlined, size: 16),
            label: const Text('Add to my Dash'),
          ),
        ],
      ),
    );
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
    final appState = AppStateScope.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(
        onToggleTheme: appState.toggleTheme,
        isDark: appState.isDarkMode,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: user != null
            ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
            : const Stream.empty(),
        builder: (context, userSnap) {
          final studentData = userSnap.data?.data() as Map<String, dynamic>?;

          return LayoutBuilder(
            builder: (context, constraints) {
              final cols = _cols(constraints.maxWidth);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Teacher & Community PDF Suggestions',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Browse auto-compiled PDF faculty notes and suggestions.',
                                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (user != null) ...[
                            Row(
                              children: [
                                const Text(
                                  'Auto Add Free',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 6),
                                Switch(
                                  value: _autoEnrollFree,
                                  activeColor: Colors.green,
                                  onChanged: _toggleAutoEnroll,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),

                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('suggestions')
                            .snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          
                          final docs = List<DocumentSnapshot>.from(snap.data?.docs ?? []).where((doc) {
                            final d = doc.data() as Map<String, dynamic>?;
                            return d?['archived'] != true;
                          }).toList();

                          docs.sort((a, b) {
                            final aData = a.data() as Map<String, dynamic>?;
                            final bData = b.data() as Map<String, dynamic>?;
                            final aTime = aData?['createdAt'] as Timestamp?;
                            final bTime = bData?['createdAt'] as Timestamp?;
                            if (aTime == null || bTime == null) return 0;
                            return bTime.compareTo(aTime);
                          });

                          if (docs.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No suggestions published yet.'),
                              ),
                            );
                          }

                          return StreamBuilder<QuerySnapshot>(
                            stream: user != null
                                ? FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .collection('saved_suggestions')
                                    .snapshots()
                                : const Stream.empty(),
                            builder: (context, savedSnap) {
                              final savedIds = (savedSnap.data?.docs ?? [])
                                  .map((e) => e.id)
                                  .toSet();

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: docs.length,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: cols == 1 ? 1.4 : 0.62,
                                ),
                                itemBuilder: (ctx, i) {
                                  final docId = docs[i].id;
                                  final d = docs[i].data() as Map<String, dynamic>;
                                  final img = _imageBytes(d);
                                  final isFree = d['isFree'] ?? true;
                                  final price = d['price'] ?? 0;
                                  final targetClass = d['class'];
                                  final title = d['title'] ?? 'Untitled';

                                  final matchesProfile = _matchesStudentProfile(d, studentData);
                                  final isSaved = savedIds.contains(docId) ||
                                      (_autoEnrollFree && isFree && matchesProfile);

                                  return Card(
                                    clipBehavior: Clip.antiAlias,
                                    elevation: 1,
                                    child: InkWell(
                                      onTap: () => _viewSuggestionDetails(context, docId, d),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceBetween,
                                              children: [
                                                const Icon(
                                                  Icons.picture_as_pdf,
                                                  size: 28,
                                                  color: Colors.red,
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: (isFree
                                                            ? Colors.green
                                                            : Colors.deepOrange)
                                                        .withOpacity(0.12),
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isFree ? 'FREE PDF' : '৳$price',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: isFree
                                                          ? Colors.green.shade800
                                                          : Colors.deepOrange.shade800,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            if (img != null)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.memory(
                                                  img,
                                                  height: cols == 1 ? 80 : 85,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            Text(
                                              title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (targetClass != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                '$targetClass • ${d['group'] ?? ''} • ${d['subDepartment'] ?? ''} • ${d['subject'] ?? 'General'}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.royalBlue,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 6),
                                            Expanded(
                                              child: Text(
                                                d['body'] ?? '',
                                                maxLines: cols == 1 ? 2 : 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  color: AppTheme.textMuted,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isSaved
                                                      ? Colors.grey.shade200
                                                  : AppTheme.royalBlue,
                                                  foregroundColor: isSaved
                                                      ? Colors.black87
                                                      : Colors.white,
                                                  elevation: isSaved ? 0 : 2,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 6),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                onPressed: isSaved
                                                    ? null
                                                    : () => _addToDashboard(docId, title),
                                                icon: Icon(
                                                  isSaved
                                                      ? Icons.check
                                                      : Icons.add_to_photos_outlined,
                                                  size: 14,
                                                ),
                                                label: Text(
                                                  isSaved ? 'Enrolled' : 'Add to my Dash',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold),
                                                ),
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
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}