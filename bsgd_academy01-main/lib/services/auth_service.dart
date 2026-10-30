import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

enum UserRole { student, teacher, guest }

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isLoggedIn => _auth.currentUser != null && _profile != null;
  bool get isStudentLoggedIn => isLoggedIn && _profile!.isStudent;
  bool get isTeacherLoggedIn => isLoggedIn && _profile!.isTeacher;

  String get currentUserName => _profile?.name ?? '';
  String get currentUserRoll => _profile?.roll ?? '';
  String get currentUserEmail => _profile?.email ?? '';
  User? get firebaseUser => _auth.currentUser;

  Future<void> init() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      final refreshed = _auth.currentUser;
      if (refreshed != null && !refreshed.emailVerified) {
        // If unverified on app init, sign them out
        await _auth.signOut();
        _profile = null;
        return;
      }
      await _loadProfile(user.uid);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        _error = 'Login failed. Please try again.';
        return false;
      }

      // CRITICAL: Refresh user to get latest email verification state from Firebase servers
      await user.reload();
      final refreshedUser = _auth.currentUser;

      final expected = expectedRole == UserRole.teacher ? 'teacher' : 'student';

      // ENFORCE EMAIL VERIFICATION FOR STUDENTS
      if (expected == 'student' && refreshedUser != null && !refreshedUser.emailVerified) {
        await _auth.signOut();
        _profile = null;
        _error = 'Please verify your email address before logging in. Check your inbox for the verification link.';
        return false;
      }

      // Strictly query the collection matching the expected role
      final profile = await _loadProfile(user.uid, expectedRole: expected);
      if (profile == null) {
        await _auth.signOut();
        _profile = null;
        _error = expectedRole == UserRole.teacher
            ? 'Access Denied: This account is NOT registered as a Teacher.'
            : 'Access Denied: This account is NOT registered as a Student.';
        return false;
      }

      if (profile.role != expected) {
        await _auth.signOut();
        _profile = null;
        _error = expectedRole == UserRole.teacher
            ? 'Access Denied: Student accounts cannot access the Teacher Hub.'
            : 'Access Denied: This is not a Student account.';
        return false;
      }

      // Update Firestore verification status if verified
      if (refreshedUser != null && refreshedUser.emailVerified) {
        await _db.collection('users').doc(user.uid).set({
          'emailVerified': true,
          'status': 'active',
        }, SetOptions(merge: true));
      }

      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      _error = 'Unexpected error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginStudent(String identifier, String password) async {
    String email = identifier.trim();

    // If identifier is a Roll Number (does not contain '@'), look up email from Firestore
    if (!email.contains('@')) {
      try {
        final query = await _db
            .collection('students')
            .where('roll', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          email = query.docs.first.data()['email'] ?? '';
        } else {
          _error = 'No student found with roll number: $identifier';
          return false;
        }
      } catch (e) {
        _error = 'Failed to lookup roll number: $e';
        return false;
      }
    }

    return signIn(
      email: email,
      password: password,
      expectedRole: UserRole.student,
    );
  }

  Future<bool> loginTeacher(String username, String password) {
    final email = username.contains('@')
        ? username.trim()
        : '${username.trim()}@bsgd.com';
    return signIn(
      email: email,
      password: password,
      expectedRole: UserRole.teacher,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _profile = null;
    _error = null;
    notifyListeners();
  }

  void logoutStudent() => signOut();
  void logoutTeacher() => signOut();

  /// Strictly loads from 'teachers' or 'students' collection without cross-access
  Future<UserProfile?> _loadProfile(String uid, {String? expectedRole}) async {
    try {
      if (expectedRole == 'teacher') {
        final doc = await _db.collection('teachers').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = Map<String, dynamic>.from(doc.data()!);
          data['role'] = 'teacher';
          _profile = UserProfile.fromMap(uid, data);
          return _profile;
        }
        return null;
      }

      if (expectedRole == 'student') {
        final doc = await _db.collection('students').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = Map<String, dynamic>.from(doc.data()!);
          data['role'] = 'student';
          _profile = UserProfile.fromMap(uid, data);
          return _profile;
        }
        return null;
      }

      // Initial app startup check: Check teachers first, then students
      final teacherDoc = await _db.collection('teachers').doc(uid).get();
      if (teacherDoc.exists && teacherDoc.data() != null) {
        final data = Map<String, dynamic>.from(teacherDoc.data()!);
        data['role'] = 'teacher';
        _profile = UserProfile.fromMap(uid, data);
        return _profile;
      }

      final studentDoc = await _db.collection('students').doc(uid).get();
      if (studentDoc.exists && studentDoc.data() != null) {
        final data = Map<String, dynamic>.from(studentDoc.data()!);
        data['role'] = 'student';
        _profile = UserProfile.fromMap(uid, data);
        return _profile;
      }

      _profile = null;
      return null;
    } catch (e) {
      debugPrint('Firestore profile load error: $e');
      _profile = null;
      return null;
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Login failed.';
    }
  }
}