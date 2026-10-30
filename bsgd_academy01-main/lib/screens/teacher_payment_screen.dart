import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherPaymentScreen extends StatelessWidget {
  const TeacherPaymentScreen({super.key});

  Future<void> _updateStatus(BuildContext context, String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(docId)
          .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order marked as $status')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('bKash Payment Verification'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
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
                child: Text('No payment requests submitted.'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final title = d['itemTitle'] ?? 'Item';
              final studentName = d['userName'] ?? 'Student';
              final price = (d['price'] ?? 0.0).toDouble();
              final status = (d['status'] ?? 'pending').toString();
              final trxId = d['trxId'] ?? '';
              final bkashNumber = d['bkashNumber'] ?? '';

              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Chip(
                            label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.white)),
                            backgroundColor: status == 'approved'
                                ? Colors.green
                                : status == 'rejected'
                                    ? Colors.red
                                    : Colors.orange,
                          ),
                        ],
                      ),
                      Text('Item: $title', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('Amount: ৳${price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SelectableText('bKash No: $bkashNumber', style: const TextStyle(fontSize: 13)),
                      SelectableText('TrxID: $trxId', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (status == 'pending')
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                onPressed: () => _updateStatus(context, doc.id, 'rejected'),
                                child: const Text('Reject'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _updateStatus(context, doc.id, 'approved'),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
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