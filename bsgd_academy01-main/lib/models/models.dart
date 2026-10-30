class Student {
  final String roll;
  final String name;
  final String studentClass;
  final String group;
  final String shift;
  final String phone;
  final String status;
  final double attendance;
  String currentStatus; // 'P', 'A', 'L'

  Student({
    required this.roll,
    required this.name,
    required this.studentClass,
    required this.group,
    required this.shift,
    required this.phone,
    required this.status,
    required this.attendance,
    this.currentStatus = 'P',
  });
}

class ExamQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  ExamQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}

class ExamResult {
  final String title;
  final String date;
  final double score;
  final double totalMarks;
  final int correct;
  final int wrong;
  final String rank;

  ExamResult({
    required this.title,
    required this.date,
    required this.score,
    required this.totalMarks,
    required this.correct,
    required this.wrong,
    required this.rank,
  });
}