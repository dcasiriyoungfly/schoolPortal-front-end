import 'package:flutter/foundation.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/data/mock_data.dart';
import 'package:schoolwebsite/services/api_service.dart';

class AppState extends ChangeNotifier {
  // ─── Auth ───────────────────────────────────────────────────────────────────
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  // ─── Mutable data ───────────────────────────────────────────────────────────
  late List<AppUser> _users;
  late List<Teacher> _teachers;
  late List<Subject> _subjects;
  late List<Student> _students;
  late List<ClassGroup> _classes;
  late List<Mark> _marks;
  late Set<String> _submittedTeacherIds;
  final List<StudentApplication> _applications = [];
  String _headmasterComment =
      'This student has demonstrated consistent effort and dedication throughout the academic year. '
      'We encourage continued focus on areas requiring improvement and commend their overall performance.';
  String _headmasterSignature = 'Headmaster\nExcellence High School';

  String get headmasterComment => _headmasterComment;
  String get headmasterSignature => _headmasterSignature;
  List<AppUser> get users => List.unmodifiable(_users);
  List<Teacher> get teachers => List.unmodifiable(_teachers);
  List<Subject> get subjects => List.unmodifiable(_subjects);
  List<Student> get students => List.unmodifiable(_students);
  List<Mark> get marks => List.unmodifiable(_marks);
  Set<String> get submittedTeacherIds => Set.unmodifiable(_submittedTeacherIds);
  List<ClassGroup> get classes => List.unmodifiable(_classes);
  List<StudentApplication> get applications => List.unmodifiable(_applications);
  int get pendingApplicationsCount => _applications.where((a) => !a.isReviewed).length;

  // ─── Loading state ──────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── Navigation (per role) ──────────────────────────────────────────────────
  int _adminPageIndex = 0;
  int _teacherPageIndex = 0;
  int _studentPageIndex = 0;

  int get adminPageIndex => _adminPageIndex;
  int get teacherPageIndex => _teacherPageIndex;
  int get studentPageIndex => _studentPageIndex;

  AppState() {
    _users = List<AppUser>.from(mockUsers);
    _teachers = [];
    _subjects = [];
    _classes = [];
    _students = [];
    _marks = [];
    _submittedTeacherIds = {};
  }

  // ── Load all live data from the API (called after login) ────────────────────
  Future<void> _loadFromApi() async {
    final api = ApiService.instance;
    final isAdmin = _currentUser?.role == UserRole.admin;
    try {
      final results = await Future.wait([
        api.fetchTeachers(),
        api.fetchSubjects(),
        api.fetchClasses(),
        api.fetchStudents(),
        api.fetchMarks(),
        if (isAdmin) api.fetchSubmittedTeacherIds() else Future.value(<String>{}),
        if (isAdmin) api.fetchApplications() else Future.value(<StudentApplication>[]),
      ]);
      _teachers = results[0] as List<Teacher>;
      _subjects = results[1] as List<Subject>;
      _classes = results[2] as List<ClassGroup>;
      _students = results[3] as List<Student>;
      _marks = results[4] as List<Mark>;
      _submittedTeacherIds = results[5] as Set<String>;
      _applications
        ..clear()
        ..addAll(results[6] as List<StudentApplication>);
    } catch (e) {
      // API unreachable — show empty data so no fake hardcoded data appears
      _teachers = [];
      _subjects = [];
      _classes = [];
      _students = [];
      _marks = [];
      _submittedTeacherIds = {};
      _applications.clear();
      rethrow;
    }
  }

  // ─── Auth methods ───────────────────────────────────────────────────────────

  bool login(String userId, String password) {
    try {
      final user = _users.firstWhere((u) => u.id == userId);
      if (user.password == password) {
        _currentUser = user;
        _adminPageIndex = 0;
        _teacherPageIndex = 0;
        _studentPageIndex = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Async login — validates against the backend API.
  /// Throws a [String] error message on failure.
  Future<bool> loginAsRoleAsync(String userId, String password, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await ApiService.instance.login(userId, password);
      final serverRole = data['role'] as String;
      if (serverRole != role) {
        _isLoading = false;
        notifyListeners();
        throw 'Incorrect User ID or password.';
      }
      ApiService.instance.setToken(data['access_token'] as String);

      // Build current user from the API response
      _currentUser = AppUser(
        id: data['user_id'] as String,
        name: data['name'] as String,
        role: UserRole.values.firstWhere((r) => r.name == serverRole),
        password: '',
        linkedId: data['linked_id'] as String?,
      );
      _adminPageIndex = 0;
      _teacherPageIndex = 0;
      _studentPageIndex = 0;

      await _loadFromApi();
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException {
      _isLoading = false;
      notifyListeners();
      throw 'Incorrect User ID or password.';
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw 'Error: $e';
    }
  }

  void logout() {
    _currentUser = null;
    ApiService.instance.clearToken();
    notifyListeners();
  }

  // ─── Navigation ─────────────────────────────────────────────────────────────

  void setAdminPage(int index) {
    _adminPageIndex = index;
    notifyListeners();
  }

  void setTeacherPage(int index) {
    _teacherPageIndex = index;
    notifyListeners();
  }

  void setStudentPage(int index) {
    _studentPageIndex = index;
    notifyListeners();
  }

  // ─── Marks management ───────────────────────────────────────────────────────

  Mark? getMark(String studentId, String subjectId) {
    try {
      return _marks.firstWhere(
        (m) => m.studentId == studentId && m.subjectId == subjectId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertMark(Mark mark) async {
    final saved = await ApiService.instance.upsertMark(mark);
    final index = _marks.indexWhere(
      (m) => m.studentId == saved.studentId && m.subjectId == saved.subjectId,
    );
    if (index >= 0) {
      _marks[index] = saved;
    } else {
      _marks.add(saved);
    }
    notifyListeners();
  }

  // ── Mark Config cache ────────────────────────────────────────────────────────

  final Map<String, MarkConfig> _markConfigCache = {};

  Future<MarkConfig> fetchMarkConfig(String subjectId, String classId) async {
    final key = '${subjectId}_$classId';
    if (_markConfigCache.containsKey(key)) return _markConfigCache[key]!;
    final config = await ApiService.instance.fetchMarkConfig(subjectId, classId);
    _markConfigCache[key] = config;
    return config;
  }

  Future<void> saveMarkConfig(MarkConfig config) async {
    final saved = await ApiService.instance.updateMarkConfig(config);
    _markConfigCache['${saved.subjectId}_${saved.classId}'] = saved;
    notifyListeners();
  }

  Future<void> markTeacherSubmitted(String teacherId) async {
    await ApiService.instance.markTeacherSubmitted(teacherId);
    _submittedTeacherIds.add(teacherId);
    notifyListeners();
  }

  // ─── Student management ─────────────────────────────────────────────────────

  Future<void> updateStudentName(String studentId, String newName) async {
    await ApiService.instance.updateStudentName(studentId, newName);
    final index = _students.indexWhere((s) => s.id == studentId);
    if (index >= 0) {
      _students[index] = _students[index].copyWith(name: newName);
      notifyListeners();
    }
  }

  /// Returns true on success, false if currentPassword is wrong.
  bool changePassword(String userId, String currentPassword, String newPassword) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index < 0) return false;
    if (_users[index].password != currentPassword) return false;
    _users[index] = AppUser(
      id: _users[index].id,
      name: _users[index].name,
      role: _users[index].role,
      password: newPassword,
      linkedId: _users[index].linkedId,
    );
    notifyListeners();
    return true;
  }

Future<void> addStudent(String name, String classId) async {
    final student = await ApiService.instance.createStudent(name, classId);
    _students.add(student);
    final ci = _classes.indexWhere((c) => c.id == classId);
    if (ci >= 0) {
      final cls = _classes[ci];
      _classes[ci] = ClassGroup(
        id: cls.id, name: cls.name,
        studentIds: [...cls.studentIds, student.id],
        teacherIds: cls.teacherIds,
      );
    }
    notifyListeners();
  }

  Future<void> deleteStudent(String studentId) async {
    await ApiService.instance.deleteStudent(studentId);
    _students.removeWhere((s) => s.id == studentId);
    _marks.removeWhere((m) => m.studentId == studentId);
    _users.removeWhere((u) => u.linkedId == studentId);
    notifyListeners();
  }

  Future<void> addClass(String name) async {
    final cls = await ApiService.instance.createClass(name);
    _classes.add(cls);
    notifyListeners();
  }

  Future<void> deleteClass(String classId) async {
    await ApiService.instance.deleteClass(classId);
    final cls = _classes.firstWhere((c) => c.id == classId,
        orElse: () => const ClassGroup(id: '', name: '', studentIds: [], teacherIds: []));
    _classes.removeWhere((c) => c.id == classId);
    _students.removeWhere((s) => s.classId == classId);
    _marks.removeWhere((m) => m.classId == classId || cls.studentIds.contains(m.studentId));
    notifyListeners();
  }

  /// Advances every class by one form at year-end.
  /// Form 4 classes graduate (deleted with their students/marks).
  /// Form 1/2/3 → renamed to Form 2/3/4 respectively.
  /// Returns the count of graduating (deleted) Form 4 students.
  int promoteClasses() {
    final graduatingClassIds = <String>[];
    final updatedClasses = <ClassGroup>[];

    for (final cls in _classes) {
      // Match "Form 4", "Form 4A", "Form 4B", etc.
      final match = RegExp(r'^Form (\d+)(.*)$').firstMatch(cls.name);
      if (match == null) {
        updatedClasses.add(cls); // unknown format — leave as-is
        continue;
      }
      final formNumber = int.parse(match.group(1)!);
      final suffix = match.group(2) ?? '';

      if (formNumber >= 4) {
        // Form 4 graduates
        graduatingClassIds.add(cls.id);
      } else {
        // Rename to next form, keep stream suffix (e.g. A, B, C)
        updatedClasses.add(ClassGroup(
          id: cls.id,
          name: 'Form ${formNumber + 1}$suffix',
          studentIds: List.from(cls.studentIds),
          teacherIds: List.from(cls.teacherIds),
        ));
      }
    }

    // Count graduating students before removal
    final graduatingStudentIds = _students
        .where((s) => graduatingClassIds.contains(s.classId))
        .map((s) => s.id)
        .toSet();

    // Remove graduating students, their marks, and Form 4 classes
    _marks.removeWhere(
      (m) => graduatingStudentIds.contains(m.studentId) ||
          graduatingClassIds.contains(m.classId),
    );
    _students.removeWhere((s) => graduatingClassIds.contains(s.classId));
    _classes = updatedClasses;

    notifyListeners();
    return graduatingStudentIds.length;
  }

  Future<void> deleteTeacher(String teacherId) async {
    final teacher = _teachers.firstWhere(
      (t) => t.id == teacherId,
      orElse: () => const Teacher(id: '', name: '', subjectIds: [], classIds: []),
    );
    if (teacher.id.isEmpty) return;

    await ApiService.instance.deleteTeacher(teacherId);

    _subjects.removeWhere((s) => teacher.subjectIds.contains(s.id));
    _marks.removeWhere((m) => teacher.subjectIds.contains(m.subjectId));
    _submittedTeacherIds.remove(teacherId);
    _teachers.removeWhere((t) => t.id == teacherId);
    _users.removeWhere((u) => u.linkedId == teacherId);
    notifyListeners();
  }

  // ─── Teacher assignment ──────────────────────────────────────────────────────

  Teacher? getTeacher(String teacherId) {
    try {
      return _teachers.firstWhere((t) => t.id == teacherId);
    } catch (_) {
      return null;
    }
  }

  Future<void> setTeacherClasses(String teacherId, List<String> classIds) async {
    final updated = await ApiService.instance.updateTeacherClasses(teacherId, classIds);
    final index = _teachers.indexWhere((t) => t.id == teacherId);
    if (index >= 0) {
      _teachers[index] = updated;
      notifyListeners();
    }
  }

  Future<void> setTeacherSubjects(String teacherId, List<String> subjectIds) async {
    final updated = await ApiService.instance.updateTeacherSubjects(teacherId, subjectIds);
    final index = _teachers.indexWhere((t) => t.id == teacherId);
    if (index >= 0) {
      _teachers[index] = updated;
      notifyListeners();
    }
  }

  /// Add a brand-new teacher, their subjects, and a login account.
/// Adds a teacher and returns the auto-generated User ID.
  Future<String> addTeacher({
    required String name,
    required String password,
    required List<String> subjectNames,
    required List<String> classIds,
  }) async {
    final result = await ApiService.instance.createTeacher(
      name: name,
      password: password,
      subjectNames: subjectNames,
      classIds: classIds,
    );

    _teachers.add(result.teacher);

    // Add the new subjects to local state
    final newSubjects = result.teacher.subjectIds.asMap().entries.map((e) {
      final name = subjectNames.length > e.key ? subjectNames[e.key] : '';
      return Subject(id: e.value, name: name, teacherId: result.teacher.id);
    }).toList();
    _subjects.addAll(newSubjects);

    _users.add(AppUser(
      id: result.userId,
      name: name,
      role: UserRole.teacher,
      password: '',
      linkedId: result.teacher.id,
    ));

    notifyListeners();
    return result.userId;
  }

  Subject? getSubject(String subjectId) {
    try {
      return _subjects.firstWhere((s) => s.id == subjectId);
    } catch (_) {
      return null;
    }
  }

  Student? getStudent(String studentId) {
    try {
      return _students.firstWhere((s) => s.id == studentId);
    } catch (_) {
      return null;
    }
  }

  List<Student> getStudentsInClass(String classId) {
    return _students.where((s) => s.classId == classId).toList();
  }

  // ─── Headmaster content ─────────────────────────────────────────────────────

  void updateHeadmasterComment(String comment) {
    _headmasterComment = comment;
    notifyListeners();
  }

  void updateHeadmasterSignature(String signature) {
    _headmasterSignature = signature;
    notifyListeners();
  }

  // ─── Applications ───────────────────────────────────────────────────────────

  Future<void> submitApplication(StudentApplication app) async {
    final saved = await ApiService.instance.submitApplication(app);
    _applications.insert(0, saved);
    notifyListeners();
  }

  Future<void> markApplicationReviewed(String id) async {
    await ApiService.instance.reviewApplication(id);
    final i = _applications.indexWhere((a) => a.id == id);
    if (i >= 0) {
      _applications[i] = _applications[i].copyWith(isReviewed: true);
      notifyListeners();
    }
  }

  Future<void> deleteApplication(String id) async {
    await ApiService.instance.deleteApplicationRemote(id);
    _applications.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // ─── Analytics ──────────────────────────────────────────────────────────────

  /// Returns pass rate as a percentage (0–100), or -1 if no marks submitted.
  double getPassRate(String teacherId) {
    final teacher = _teachers.firstWhere(
      (t) => t.id == teacherId,
      orElse: () => const Teacher(id: '', name: '', subjectIds: [], classIds: []),
    );
    if (teacher.id.isEmpty) return -1;

    int total = 0;
    int passing = 0;

    for (final classId in teacher.classIds) {
      final classGroup = _classes.firstWhere(
        (c) => c.id == classId,
        orElse: () => const ClassGroup(id: '', name: '', studentIds: [], teacherIds: []),
      );
      if (classGroup.id.isEmpty) continue;

      for (final studentId in classGroup.studentIds) {
        for (final subjectId in teacher.subjectIds) {
          final mark = getMark(studentId, subjectId);
          if (mark != null) {
            total++;
            if (mark.isPassing) passing++;
          }
        }
      }
    }

    if (total == 0) return -1;
    return (passing / total) * 100;
  }

  String? getHighestPerformingTeacherId() {
    double highest = -1;
    String? topId;
    for (final teacher in _teachers) {
      final rate = getPassRate(teacher.id);
      if (rate > highest) {
        highest = rate;
        topId = teacher.id;
      }
    }
    return topId;
  }

  List<String> getMarksForStudent(String studentId) {
    return _marks
        .where((m) => m.studentId == studentId)
        .map((m) => m.subjectId)
        .toList();
  }
}
