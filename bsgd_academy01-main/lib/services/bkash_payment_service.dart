import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BkashPaymentService {
  static Future<bool> hasPurchasedItem(String itemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // Check approved payments in the payments collection
    final snap = await FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: user.uid)
        .where('itemId', isEqualTo: itemId)
        .where('status', isEqualTo: 'approved')
        .get();

    if (snap.docs.isNotEmpty) return true;

    // Fallback legacy purchases check
    final legacySnap = await FirebaseFirestore.instance
        .collection('purchases')
        .where('userId', isEqualTo: user.uid)
        .where('itemId', isEqualTo: itemId)
        .get();

    return legacySnap.docs.isNotEmpty;
  }
}