enum UserRole { admin, teacher, student }

class StudentApplication {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String formApplyingFor;
  final String previousSchool;
  final String reasonForLeaving;
  final String? resultsFileName;
  final DateTime submittedAt;
  final bool isReviewed;

  const StudentApplication({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.formApplyingFor,
    required this.previousSchool,
    required this.reasonForLeaving,
    this.resultsFileName,
    required this.submittedAt,
    this.isReviewed = false,
  });

  StudentApplication copyWith({bool? isReviewed}) {
    return StudentApplication(
      id: id,
      fullName: fullName,
      email: email,
      phone: phone,
      formApplyingFor: formApplyingFor,
      previousSchool: previousSchool,
      reasonForLeaving: reasonForLeaving,
      resultsFileName: resultsFileName,
      submittedAt: submittedAt,
      isReviewed: isReviewed ?? this.isReviewed,
    );
  }
}

class AppUser {
  final String id;
  final String name;
  final UserRole role;
  final String password;
  final String? linkedId;

  const AppUser({
    required this.id,
    required this.name,
    required this.role,
    required this.password,
    this.linkedId,
  });
}

class Teacher {
  final String id;
  final String name;
  final List<String> subjectIds;
  final List<String> classIds;

  const Teacher({
    required this.id,
    required this.name,
    required this.subjectIds,
    required this.classIds,
  });

  Teacher copyWith({List<String>? subjectIds, List<String>? classIds}) {
    return Teacher(
      id: id,
      name: name,
      subjectIds: subjectIds ?? List.from(this.subjectIds),
      classIds: classIds ?? List.from(this.classIds),
    );
  }
}

class Student {
  final String id;
  final String name;
  final String classId;

  const Student({
    required this.id,
    required this.name,
    required this.classId,
  });

  Student copyWith({String? name}) {
    return Student(id: id, name: name ?? this.name, classId: classId);
  }
}

class ClassGroup {
  final String id;
  final String name;
  final List<String> studentIds;
  final List<String> teacherIds;

  const ClassGroup({
    required this.id,
    required this.name,
    required this.studentIds,
    required this.teacherIds,
  });
}

class Subject {
  final String id;
  final String name;
  final String teacherId;

  const Subject({
    required this.id,
    required this.name,
    required this.teacherId,
  });
}

// ── Mark Config ───────────────────────────────────────────────────────────────

class MarkComponent {
  final String id;
  final String name;
  final double maxMark;

  const MarkComponent({
    required this.id,
    required this.name,
    required this.maxMark,
  });
}

class MarkConfig {
  final String subjectId;
  final String classId;
  final List<MarkComponent> termComponents;
  final List<MarkComponent> examComponents;

  const MarkConfig({
    required this.subjectId,
    required this.classId,
    this.termComponents = const [],
    this.examComponents = const [],
  });

  MarkConfig copyWith({
    List<MarkComponent>? termComponents,
    List<MarkComponent>? examComponents,
  }) {
    return MarkConfig(
      subjectId: subjectId,
      classId: classId,
      termComponents: termComponents ?? this.termComponents,
      examComponents: examComponents ?? this.examComponents,
    );
  }
}

// ── Mark ──────────────────────────────────────────────────────────────────────

class MarkEntry {
  final String componentId;
  final double mark;

  const MarkEntry({required this.componentId, required this.mark});
}

class Mark {
  final String studentId;
  final String subjectId;
  final String classId;
  final List<MarkEntry> termEntries;
  final List<MarkEntry> examEntries;
  final double termPercentage;
  final double examPercentage;

  const Mark({
    required this.studentId,
    required this.subjectId,
    required this.classId,
    this.termEntries = const [],
    this.examEntries = const [],
    this.termPercentage = 0,
    this.examPercentage = 0,
  });

  double get finalMark => (termPercentage * 0.4) + (examPercentage * 0.6);

  String get grade {
    final m = finalMark;
    if (m >= 80) return 'A';
    if (m >= 70) return 'B';
    if (m >= 60) return 'C';
    if (m >= 50) return 'D';
    return 'F';
  }

  bool get isPassing => finalMark >= 50;

  Mark copyWith({
    List<MarkEntry>? termEntries,
    List<MarkEntry>? examEntries,
    double? termPercentage,
    double? examPercentage,
  }) {
    return Mark(
      studentId: studentId,
      subjectId: subjectId,
      classId: classId,
      termEntries: termEntries ?? this.termEntries,
      examEntries: examEntries ?? this.examEntries,
      termPercentage: termPercentage ?? this.termPercentage,
      examPercentage: examPercentage ?? this.examPercentage,
    );
  }
}
