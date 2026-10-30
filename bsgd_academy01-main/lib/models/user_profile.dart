/// User profile stored in Firestore collection `users`.
/// Document ID = Firebase Auth UID.
class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String role; // "student" | "teacher"
  final String? roll;
  final String? studentClass;
  final String? group;
  final String? shift;
  final String? phone;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.roll,
    this.studentClass,
    this.group,
    this.shift,
    this.phone,
  });

  bool get isTeacher => role == 'teacher';
  bool get isStudent => role == 'student';

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'student',
      roll: data['roll'] as String?,
      studentClass: data['studentClass'] as String?,
      group: data['group'] as String?,
      shift: data['shift'] as String?,
      phone: data['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      if (roll != null) 'roll': roll,
      if (studentClass != null) 'studentClass': studentClass,
      if (group != null) 'group': group,
      if (shift != null) 'shift': shift,
      if (phone != null) 'phone': phone,
    };
  }
}
