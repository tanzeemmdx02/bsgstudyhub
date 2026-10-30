import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ai_suggestion_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/html_pdf_printer.dart';

const _bn = TextStyle(
  fontFamily: 'Noto Sans Bengali',
  fontFamilyFallback: ['Hind Siliguri', 'Kalpurush', 'SolaimanLipi', 'Arial'],
  height: 1.5,
);

// ============================================================================
// 1. AI SUGGESTION HUB (LIST + GENERATE BUTTONS)
// ============================================================================
class TeacherAiSuggestionsScreen extends StatefulWidget {
  const TeacherAiSuggestionsScreen({super.key});

  @override
  State<TeacherAiSuggestionsScreen> createState() =>
      _TeacherAiSuggestionsScreenState();
}

class _TeacherAiSuggestionsScreenState extends State<TeacherAiSuggestionsScreen> {
  bool _loading = false;

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
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // Upload file and generate CQ Suggestion
  Future<void> _handleGenerateCq() async {
    if (!AiSuggestionService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing GEMINI_API_KEY.')),
      );
      return;
    }

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (file == null) return;

      _showLoading('AI analyzing CQ paper & generating answers…');
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final mime = name.endsWith('.pdf')
          ? 'application/pdf'
          : (name.endsWith('.png') ? 'image/png' : 'image/jpeg');

      final result = await AiSuggestionService.generateCq(
        bytes: bytes,
        mimeType: mime,
      );

      _closeLoading();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CqSuggestionDetailScreen(data: result),
        ),
      );
    } catch (e) {
      _closeLoading();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  // Upload file and generate Short Suggestion
  Future<void> _handleGenerateShort() async {
    if (!AiSuggestionService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing GEMINI_API_KEY.')),
      );
      return;
    }

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      if (file == null) return;

      _showLoading('Generating short suggestion & key points…');
      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      final mime = name.endsWith('.pdf')
          ? 'application/pdf'
          : (name.endsWith('.png') ? 'image/png' : 'image/jpeg');

      final result = await AiSuggestionService.generateShort(
        bytes: bytes,
        mimeType: mime,
      );

      _closeLoading();

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShortSuggestionDetailScreen(data: result),
        ),
      );
    } catch (e) {
      _closeLoading();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('AI Suggestion Hub', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          // Generate Short Suggestion Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.royalBlue,
                side: const BorderSide(color: AppTheme.royalBlue),
              ),
              onPressed: _handleGenerateShort,
              icon: const Icon(Icons.flash_on, size: 16),
              label: const Text('Generate Short Suggestion', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),

          // CQ Suggestion Button
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 14, 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.academicGold,
                foregroundColor: Colors.black87,
              ),
              onPressed: _handleGenerateCq,
              icon: const Icon(Icons.psychology, size: 18),
              label: const Text('CQ Suggestion', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('suggestions')
            .where('isAiGenerated', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.royalBlue.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, size: 48, color: AppTheme.royalBlue),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No AI Suggestions Generated Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Click "CQ Suggestion" to solve a full Creative Question,\nor "Generate Short Suggestion" for high-yield revision points.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: AppTheme.royalBlue),
                          onPressed: _handleGenerateCq,
                          icon: const Icon(Icons.psychology),
                          label: const Text('Upload & Solve CQ'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _handleGenerateShort,
                          icon: const Icon(Icons.flash_on),
                          label: const Text('Short Suggestion'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final isCq = d['suggestionType'] == 'cq';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isCq
                        ? AppTheme.academicGold.withOpacity(0.2)
                        : AppTheme.royalBlue.withOpacity(0.12),
                    child: Icon(
                      isCq ? Icons.psychology : Icons.flash_on,
                      color: isCq ? Colors.amber.shade900 : AppTheme.royalBlue,
                    ),
                  ),
                  title: Text(
                    d['title'] ?? 'Suggestion',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  subtitle: Text(
                    isCq ? 'Creative Question & Detailed Answers (ক, খ, গ, ঘ)' : 'Short Suggestion Notes',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => doc.reference.delete(),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    if (isCq) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CqSuggestionDetailScreen(
                            data: CqSuggestionData.fromJson(d['cqData'] ?? {}),
                            isSaved: true,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// 2. CQ SUGGESTION DETAIL SCREEN (PASSAGE BAR + QUESTION BARS + PDF + PUBLISH)
// ============================================================================
class CqSuggestionDetailScreen extends StatefulWidget {
  final CqSuggestionData data;
  final bool isSaved;

  const CqSuggestionDetailScreen({
    super.key,
    required this.data,
    this.isSaved = false,
  });

  @override
  State<CqSuggestionDetailScreen> createState() => _CqSuggestionDetailScreenState();
}

class _CqSuggestionDetailScreenState extends State<CqSuggestionDetailScreen> {
  // Map of question index -> whether detailed answer is expanded
  final Map<int, bool> _expandedDetails = {};
  bool _saving = false;

  Future<void> _publish() async {
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final teacherName = AuthService().currentUserName.isNotEmpty
          ? AuthService().currentUserName
          : 'Faculty';

      // Build plain text for backward compatibility with general suggestions list
      final buffer = StringBuffer();
      buffer.writeln('উদ্দীপক:');
      buffer.writeln(widget.data.passage);
      buffer.writeln();
      for (final item in widget.data.items) {
        buffer.writeln('প্রশ্ন ${item.label}: ${item.question}');
        buffer.writeln('সংক্ষিপ্ত উত্তর: ${item.shortAnswer}');
        buffer.writeln('বিস্তারিত উত্তর: ${item.detailedAnswer}');
        buffer.writeln();
      }

      await FirebaseFirestore.instance.collection('suggestions').add({
        'title': widget.data.title,
        'body': buffer.toString().trim(),
        'teacherId': uid,
        'teacherName': teacherName,
        'isAiGenerated': true,
        'suggestionType': 'cq',
        'cqData': widget.data.toJson(),
        'archived': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CQ Suggestion published successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publish failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportPdf() async {
    final itemsHtml = StringBuffer();
    for (final item in widget.data.items) {
      itemsHtml.write('''
        <div style="margin-bottom: 16px; border: 1px solid #e2e8f0; border-radius: 6px; padding: 12px; background: #fff;">
          <div style="font-weight: 800; color: #1e3a8a; font-size: 13.5px; margin-bottom: 6px;">
            প্রশ্ন ${item.label}: ${item.question}
          </div>
          <div style="background: #ecfdf5; border-left: 3px solid #10b981; padding: 6px 10px; margin-bottom: 8px; font-size: 12.5px;">
            <strong>সংক্ষিপ্ত উত্তর:</strong> ${item.shortAnswer}
          </div>
          <div style="font-size: 12.5px; line-height: 1.6; color: #334155;">
            <strong>বিস্তারিত উত্তর:</strong><br>
            ${item.detailedAnswer.replaceAll('\n', '<br>')}
          </div>
        </div>
      ''');
    }

    final html = '''
<!DOCTYPE html>
<html lang="bn">
<head>
  <meta charset="utf-8">
  <title>${widget.data.title}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+Bengali:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    @page { size: A4 portrait; margin: 15mm 15mm; }
    body { font-family: 'Noto Sans Bengali', Arial, sans-serif; margin: 0; color: #0f172a; font-size: 13px; line-height: 1.5; }
    .header { text-align: center; border-bottom: 2px solid #1e3a8a; padding-bottom: 8px; margin-bottom: 14px; }
    .inst-name { font-size: 20px; font-weight: 800; color: #1e3a8a; }
    .title { font-size: 14px; font-weight: 700; color: #b45309; margin-top: 4px; }
    .passage-bar { background: #fffbeb; border: 1.5px solid #d97706; border-radius: 6px; padding: 12px 14px; margin-bottom: 16px; }
    .passage-tag { font-weight: 800; color: #b45309; font-size: 12px; margin-bottom: 4px; }
    .passage-text { font-weight: 600; font-size: 13px; line-height: 1.6; }
  </style>
</head>
<body>
  <div class="header">
    <div class="inst-name">BSGD ACADEMY</div>
    <div class="title">${widget.data.title}</div>
  </div>

  <div class="passage-bar">
    <div class="passage-tag">উদ্দীপক:</div>
    <div class="passage-text">${widget.data.passage.replaceAll('\n', '<br>')}</div>
  </div>

  $itemsHtml

  <script>
    window.addEventListener('load', () => { setTimeout(() => { window.print(); }, 350); });
  </script>
</body>
</html>
''';

    await printOrExportHtml(html, widget.data.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(widget.data.title, style: _bn.copyWith(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
          ),
          if (!widget.isSaved)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.academicGold,
                  foregroundColor: Colors.black87,
                ),
                onPressed: _saving ? null : _publish,
                icon: const Icon(Icons.publish, size: 18),
                label: Text(_saving ? 'Publishing…' : 'Publish Suggestion'),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ==========================================
          // 1. PASSAGE BAR (উদ্দীপক)
          // ==========================================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD4A333), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.subject, color: Color(0xFF8B6914), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'উদ্দীপক (Stimulus / Scenario)',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF8B6914),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  widget.data.passage,
                  style: _bn.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'সৃজনশীল প্রশ্ন ও সমাধান (Click question to view answers)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          // ==========================================
          // 2. QUESTION BARS (ক, খ, গ, ঘ)
          // ==========================================
          ...List.generate(widget.data.items.length, (index) {
            final item = widget.data.items[index];
            final showDetail = _expandedDetails[index] == true;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.royalBlue.withOpacity(0.12),
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: AppTheme.royalBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                title: Text(
                  'প্রশ্ন ${item.label}: ${item.question}',
                  style: _bn.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),

                        // SHORT ANSWER BOX
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bolt, color: Colors.green, size: 18),
                                  SizedBox(width: 4),
                                  Text(
                                    'সংক্ষিপ্ত উত্তর (Quick Answer):',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.green,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                item.shortAnswer,
                                style: _bn.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),

                        // TOGGLE DETAILED ANSWER BUTTON
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            setState(() {
                              _expandedDetails[index] = !showDetail;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: showDetail ? Colors.blue.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  showDetail ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: AppTheme.royalBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  showDetail ? 'বিস্তারিত উত্তর লুকান' : 'বিস্তারিত উত্তর দেখুন (Click to see detailed answer)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: AppTheme.royalBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // DETAILED ANSWER ACCORDION
                        if (showDetail) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'বিস্তারিত উত্তর (Detailed Answer):',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  item.detailedAnswer,
                                  style: _bn.copyWith(
                                    fontSize: 13.5,
                                    height: 1.6,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}

// ============================================================================
// 3. SHORT SUGGESTION DETAIL SCREEN
// ============================================================================
class ShortSuggestionDetailScreen extends StatelessWidget {
  final ShortSuggestionData data;

  const ShortSuggestionDetailScreen({super.key, required this.data});

  Future<void> _exportPdf() async {
    final pointsHtml = data.keyPoints
        .map((p) => '<li style="margin-bottom: 8px;">$p</li>')
        .join();

    final qaHtml = data.shortQuestions.map((item) {
      return '''
        <div style="margin-bottom: 12px; padding: 10px; background: #f8fafc; border-left: 3px solid #3b82f6;">
          <strong>প্রশ্ন: ${item['q']}</strong><br>
          <span style="color: #334155;">উত্তর: ${item['a']}</span>
        </div>
      ''';
    }).join();

    final html = '''
<!DOCTYPE html>
<html lang="bn">
<head>
  <meta charset="utf-8">
  <title>${data.title}</title>
  <style>
    @page { size: A4 portrait; margin: 15mm; }
    body { font-family: Arial, sans-serif; font-size: 13px; line-height: 1.5; color: #0f172a; }
    .header { text-align: center; border-bottom: 2px solid #1e3a8a; padding-bottom: 8px; margin-bottom: 16px; }
    .inst-name { font-size: 20px; font-weight: bold; color: #1e3a8a; }
  </style>
</head>
<body>
  <div class="header">
    <div class="inst-name">BSGD ACADEMY</div>
    <div>${data.title} (${data.subject}) - সংক্ষিপ্ত সাজেশন</div>
  </div>

  <h3>মূল পয়েন্ট ও শর্ট সাজেশন:</h3>
  <ul>$pointsHtml</ul>

  <h3>গুরুত্বপূর্ণ প্রশ্ন ও উত্তর:</h3>
  $qaHtml
  <script>window.addEventListener('load', () => { setTimeout(() => { window.print(); }, 350); });</script>
</body>
</html>
''';

    await printOrExportHtml(html, data.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text('${data.title} - সংক্ষিপ্ত সাজেশন', style: _bn),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber),
                      SizedBox(width: 8),
                      Text('গুরুত্বপূর্ণ পয়েন্ট (High-Yield Points):', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...data.keyPoints.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Expanded(child: SelectableText(p, style: _bn)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('জ্ঞানমূলক ও অনুধাবনমূলক প্রশ্ন:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          ...data.shortQuestions.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('প্রশ্ন: ${item['q']}', style: _bn.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('উত্তর: ${item['a']}', style: _bn.copyWith(color: Colors.green.shade800)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}