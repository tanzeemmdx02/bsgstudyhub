import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/student_login_screen.dart';
import '../services/bkash_payment_service.dart';
import '../theme/app_theme.dart';
import '../utils/file_download.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/bkash_payment_modal.dart';

class NoticeScreen extends StatelessWidget {
  const NoticeScreen({super.key});

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

  Future<void> _handleItemTap(BuildContext context, String docId, Map<String, dynamic> d) async {
    final isFree = d['isFree'] ?? true;
    final price = (d['price'] ?? 0.0).toDouble();

    if (!isFree && price > 0) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first to purchase paid notices/notes.')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
        );
        return;
      }

      final alreadyUnlocked = await BkashPaymentService.hasPurchasedItem(docId);

      if (!alreadyUnlocked) {
        if (!context.mounted) return;

        final paidSuccess = await BkashPaymentModal.show(
          context,
          itemId: docId,
          itemType: 'notice',
          itemTitle: d['title'] ?? 'Paid Notice',
          price: price,
        );

        if (paidSuccess != true) {
          return;
        }
      }
    }

    if (!context.mounted) return;
    _openDetail(context, d);
  }

  void _openDetail(BuildContext context, Map<String, dynamic> d) {
    final img = _imageBytes(d);
    final isPdf = d['attachmentType'] == 'pdf';
    final b64 = d['attachmentBase64']?.toString();
    final name =
        d['attachmentName']?.toString() ?? (isPdf ? 'file.pdf' : 'image.jpg');
    final isFree = d['isFree'] ?? true;
    final price = d['price'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(d['title']?.toString() ?? 'Notice'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isFree ? Colors.green : Colors.deepOrange)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isFree ? 'FREE' : 'PRICE: ৳$price',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFree
                            ? Colors.green.shade800
                            : Colors.deepOrange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (d['class'] != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.royalBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Class: ${d['class']} • Dept: ${d['group'] ?? 'General'} • Section: ${d['subDepartment'] ?? 'General'} • Subject: ${d['subject'] ?? 'General'}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.royalBlue,
                    ),
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
              if (isPdf && b64 != null && b64.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(name)),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (b64 != null && b64.isNotEmpty) ...[
            TextButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text('View'),
              onPressed: () => viewBase64File(
                context: context,
                base64Data: b64,
                type: d['attachmentType']?.toString() ?? 'image',
                fileName: name,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download'),
              onPressed: () => downloadBase64File(
                context: context,
                base64Data: b64,
                fileName: name,
                type: d['attachmentType']?.toString() ?? 'image',
              ),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppNavBar(
        onToggleTheme: appState.toggleTheme,
        isDark: appState.isDarkMode,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cols = _cols(constraints.maxWidth);
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Notices & Notes',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Important updates & lecture notes from teachers.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notes')
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final docs = (snap.data?.docs ?? []).where((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return d['archived'] != true;
                      }).toList();

                      if (docs.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No notices published yet.'),
                          ),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: cols == 1 ? 2.2 : 0.85,
                        ),
                        itemBuilder: (ctx, i) {
                          final docId = docs[i].id;
                          final d = docs[i].data() as Map<String, dynamic>;
                          final isPdf = d['attachmentType'] == 'pdf';
                          final img = _imageBytes(d);
                          final isFree = d['isFree'] ?? true;
                          final price = d['price'] ?? 0;
                          final targetClass = d['class'];

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 1,
                            child: InkWell(
                              onTap: () => _handleItemTap(context, docId, d),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          isPdf
                                              ? Icons.picture_as_pdf
                                              : Icons.campaign_outlined,
                                          size: 28,
                                          color: isPdf
                                              ? Colors.red
                                              : AppTheme.royalBlue,
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
                                            isFree ? 'FREE' : '৳$price',
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
                                          height: cols == 1 ? 80 : 90,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      d['title'] ?? 'Untitled',
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
                                        '$targetClass • ${d['subject'] ?? ''}',
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
                                  ],
                                ),
                              ),
                            ),
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
      ),
    );
  }
}