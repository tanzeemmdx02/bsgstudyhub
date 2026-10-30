import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StudentPaymentScreen extends StatelessWidget {
  const StudentPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Payments')),
        body: const Center(child: Text('Please log in to view your payment history.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Payments & Orders'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No payment requests submitted yet.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final title = d['itemTitle'] ?? 'Item';
              final price = (d['price'] ?? 0.0).toDouble();
              final status = (d['status'] ?? 'pending').toString();
              final trxId = d['trxId'] ?? '';
              final bkashNumber = d['bkashNumber'] ?? '';

              Color statusColor = Colors.orange;
              IconData statusIcon = Icons.hourglass_top;

              if (status == 'approved') {
                statusColor = Colors.green;
                statusIcon = Icons.check_circle_outline;
              } else if (status == 'rejected') {
                statusColor = Colors.red;
                statusIcon = Icons.cancel_outlined;
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(statusIcon, color: statusColor, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text('Amount: ৳${price.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.royalBlue)),
                      const SizedBox(height: 4),
                      Text('TrxID: $trxId', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      Text('bKash Number: $bkashNumber', style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                      if (status == 'pending') ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Will get in under 24 hours',
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic),
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
    );
  }
}