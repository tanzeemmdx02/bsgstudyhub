import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BkashPaymentModal extends StatefulWidget {
  final String itemId;
  final String itemType; // 'course', 'suggestion', 'note', etc.
  final String itemTitle;
  final double price;

  const BkashPaymentModal({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemTitle,
    required this.price,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String itemId,
    required String itemType,
    required String itemTitle,
    required double price,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BkashPaymentModal(
        itemId: itemId,
        itemType: itemType,
        itemTitle: itemTitle,
        price: price,
      ),
    );
  }

  @override
  State<BkashPaymentModal> createState() => _BkashPaymentModalState();
}

class _BkashPaymentModalState extends State<BkashPaymentModal> {
  final _phoneCtrl = TextEditingController();
  final _trxCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _trxCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final phone = _phoneCtrl.text.trim();
    final trxId = _trxCtrl.text.trim();

    if (phone.isEmpty || trxId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter bKash number and TrxID')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // 1. Create a pending payment request doc
      await FirebaseFirestore.instance.collection('payments').add({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'userName': user.displayName ?? 'Student',
        'itemId': widget.itemId,
        'itemType': widget.itemType,
        'itemTitle': widget.itemTitle,
        'price': widget.price,
        'bkashNumber': phone,
        'trxId': trxId,
        'status': 'pending', // 'pending', 'approved', 'rejected'
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 2. Show Thank you message
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Text('Order Submitted'),
            ],
          ),
          content: const Text(
            'Thank u for order. Will get in under 24 hours',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'bKash Payment',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.pink.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Amount to Pay: ৳${widget.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to pay via bKash:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text('1. Go to your bKash App or dial *247#', style: TextStyle(fontSize: 12)),
                    Text('2. Select Send Money to: 01712317214',
                        style: TextStyle(fontSize: 12, color: Colors.pink, fontWeight: FontWeight.bold)),
                    Text('3. Enter amount and confirm PIN.', style: TextStyle(fontSize: 12)),
                    Text('4. Paste your bKash Account Number & TrxID below.', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Your bKash Account Number *',
                  prefixIcon: Icon(Icons.phone_android, color: Colors.pink),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _trxCtrl,
                decoration: const InputDecoration(
                  labelText: 'bKash Transaction ID (TrxID) *',
                  prefixIcon: Icon(Icons.receipt_long, color: Colors.pink),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _submitting ? null : _submitOrder,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm Payment & Unlock',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}