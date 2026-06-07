import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:schoolwebsite/models/models.dart';

/// Change this to your backend URL.
/// Local dev:  http://localhost:8000
/// Cloud workstation: https://8000-YOUR_WORKSTATION_ID.cloudworkstations.dev
const String kApiBaseUrl = 'http://localhost:8000';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$kApiBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    final detail = _errorDetail(res.body);
    throw ApiException(detail);
  }

  Future<dynamic> _get(String path) async {
    final res = await http.get(Uri.parse('$kApiBaseUrl$path'), headers: _headers);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw ApiException(_errorDetail(res.body));
  }

  Future<void> _delete(String path) async {
    final res = await http.delete(Uri.parse('$kApiBaseUrl$path'), headers: _headers);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_errorDetail(res.body));
    }
  }

  Future<dynamic> _put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$kApiBaseUrl$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw ApiException(_errorDetail(res.body));
  }

  String _errorDetail(String body) {
    try {
      return jsonDecode(body)['detail'] ?? 'Request failed';
    } catch (_) {
      return 'Request failed';
    }
  }

  // ── Auth ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String userId, String password) async {
    final data = await _post('/auth/login', {'user_id': userId, 'password': password});
    return data as Map<String, dynamic>;
  }

  // ── Load all data ────────────────────────────────────────────────────────────

  Future<List<Teacher>> fetchTeachers() async {
    final data = await _get('/teachers/') as List;
    return data.map((d) => Teacher(
          id: d['id'],
          name: d['name'],
          subjectIds: List<String>.from(d['subject_ids'] ?? []),
          classIds: List<String>.from(d['class_ids'] ?? []),
        )).toList();
  }

  Future<List<Subject>> fetchSubjects() async {
    final data = await _get('/subjects/') as List;
    return data.map((d) => Subject(
          id: d['id'],
          name: d['name'],
          teacherId: d['teacher_id'],
        )).toList();
  }

  Future<List<ClassGroup>> fetchClasses() async {
    final data = await _get('/classes/') as List;
    return data.map((d) => ClassGroup(
          id: d['id'],
          name: d['name'],
          studentIds: List<String>.from(d['student_ids'] ?? []),
          teacherIds: List<String>.from(d['teacher_ids'] ?? []),
        )).toList();
  }

  Future<List<Student>> fetchStudents() async {
    final data = await _get('/students/') as List;
    return data.map((d) => Student(
          id: d['id'],
          name: d['name'],
          classId: d['class_id'],
        )).toList();
  }

  Future<List<Mark>> fetchMarks() async {
    final data = await _get('/marks/') as List;
    return data.map(_markFromJson).toList();
  }

  Future<Set<String>> fetchSubmittedTeacherIds() async {
    final data = await _get('/admin/submission-status') as List;
    return data
        .where((d) => d['submitted'] == true)
        .map<String>((d) => d['teacher_id'] as String)
        .toSet();
  }

  // ── Mark Config ──────────────────────────────────────────────────────────────

  Future<MarkConfig> fetchMarkConfig(String subjectId, String classId) async {
    final data = await _get('/mark-config/$subjectId/$classId') as Map<String, dynamic>;
    return _markConfigFromJson(data);
  }

  Future<MarkConfig> updateMarkConfig(MarkConfig config) async {
    final data = await _put(
      '/mark-config/${config.subjectId}/${config.classId}',
      {
        'term_components': config.termComponents
            .map((c) => {'id': c.id, 'name': c.name, 'max_mark': c.maxMark})
            .toList(),
        'exam_components': config.examComponents
            .map((c) => {'id': c.id, 'name': c.name, 'max_mark': c.maxMark})
            .toList(),
      },
    ) as Map<String, dynamic>;
    return _markConfigFromJson(data);
  }

  MarkConfig _markConfigFromJson(Map<String, dynamic> d) {
    return MarkConfig(
      subjectId: d['subject_id'] as String,
      classId: d['class_id'] as String,
      termComponents: (d['term_components'] as List<dynamic>? ?? [])
          .map((c) => MarkComponent(
                id: c['id'] as String,
                name: c['name'] as String,
                maxMark: (c['max_mark'] as num).toDouble(),
              ))
          .toList(),
      examComponents: (d['exam_components'] as List<dynamic>? ?? [])
          .map((c) => MarkComponent(
                id: c['id'] as String,
                name: c['name'] as String,
                maxMark: (c['max_mark'] as num).toDouble(),
              ))
          .toList(),
    );
  }

  // ── Teacher CRUD ─────────────────────────────────────────────────────────────

  Future<({Teacher teacher, String userId})> createTeacher({
    required String name,
    required String password,
    required List<String> subjectNames,
    required List<String> classIds,
  }) async {
    final data = await _post('/teachers/', {
      'name': name,
      'password': password,
      'subject_names': subjectNames,
      'class_ids': classIds,
    }) as Map<String, dynamic>;

    final t = data['teacher'] as Map<String, dynamic>;
    final teacher = Teacher(
      id: t['id'],
      name: t['name'],
      subjectIds: List<String>.from(t['subject_ids'] ?? []),
      classIds: List<String>.from(t['class_ids'] ?? []),
    );
    return (teacher: teacher, userId: data['user_id'] as String);
  }

  Future<void> deleteTeacher(String teacherId) async {
    await _delete('/teachers/$teacherId');
  }

  Future<Teacher> updateTeacherClasses(String teacherId, List<String> classIds) async {
    final data = await _put('/teachers/$teacherId/classes', {'class_ids': classIds})
        as Map<String, dynamic>;
    return Teacher(
      id: data['id'],
      name: data['name'],
      subjectIds: List<String>.from(data['subject_ids'] ?? []),
      classIds: List<String>.from(data['class_ids'] ?? []),
    );
  }

  Future<Teacher> updateTeacherSubjects(String teacherId, List<String> subjectIds) async {
    final data = await _put('/teachers/$teacherId/subjects', {'subject_ids': subjectIds})
        as Map<String, dynamic>;
    return Teacher(
      id: data['id'],
      name: data['name'],
      subjectIds: List<String>.from(data['subject_ids'] ?? []),
      classIds: List<String>.from(data['class_ids'] ?? []),
    );
  }

  // ── Classes ──────────────────────────────────────────────────────────────────

  Future<ClassGroup> createClass(String name) async {
    final data = await _post('/classes/', {'name': name}) as Map<String, dynamic>;
    return ClassGroup(
      id: data['id'],
      name: data['name'],
      studentIds: List<String>.from(data['student_ids'] ?? []),
      teacherIds: List<String>.from(data['teacher_ids'] ?? []),
    );
  }

  Future<void> deleteClass(String classId) async {
    await _delete('/classes/$classId');
  }

  // ── Students ─────────────────────────────────────────────────────────────────

  Future<Student> createStudent(String name, String classId) async {
    final data = await _post('/students/', {'name': name, 'class_id': classId})
        as Map<String, dynamic>;
    return Student(id: data['id'], name: data['name'], classId: data['class_id']);
  }

  Future<void> deleteStudent(String studentId) async {
    await _delete('/students/$studentId');
  }

  Future<void> updateStudentName(String studentId, String name) async {
    await _put('/students/$studentId', {'name': name});
  }

  // ── Marks ────────────────────────────────────────────────────────────────────

  Future<Mark> upsertMark(Mark mark) async {
    final data = await _post('/marks/', {
      'student_id': mark.studentId,
      'subject_id': mark.subjectId,
      'class_id':   mark.classId,
      'term_entries': mark.termEntries
          .map((e) => {'component_id': e.componentId, 'mark': e.mark})
          .toList(),
      'exam_entries': mark.examEntries
          .map((e) => {'component_id': e.componentId, 'mark': e.mark})
          .toList(),
    }) as Map<String, dynamic>;
    return _markFromJson(data);
  }

  Mark _markFromJson(dynamic d) {
    return Mark(
      studentId: d['student_id'] as String,
      subjectId: d['subject_id'] as String,
      classId:   d['class_id'] as String,
      termEntries: (d['term_entries'] as List<dynamic>? ?? [])
          .map((e) => MarkEntry(
                componentId: e['component_id'] as String,
                mark: (e['mark'] as num).toDouble(),
              ))
          .toList(),
      examEntries: (d['exam_entries'] as List<dynamic>? ?? [])
          .map((e) => MarkEntry(
                componentId: e['component_id'] as String,
                mark: (e['mark'] as num).toDouble(),
              ))
          .toList(),
      termPercentage: (d['term_percentage'] as num? ?? 0).toDouble(),
      examPercentage: (d['exam_percentage'] as num? ?? 0).toDouble(),
    );
  }

  // ── Submissions ──────────────────────────────────────────────────────────────

  Future<void> markTeacherSubmitted(String teacherId) async {
    await _post('/admin/submission/$teacherId', {});
  }

  // ── Applications ─────────────────────────────────────────────────────────────

  Future<StudentApplication> submitApplication(StudentApplication app) async {
    final data = await _post('/applications/', {
      'full_name': app.fullName,
      'email': app.email,
      'phone': app.phone,
      'form_applying_for': app.formApplyingFor,
      'previous_school': app.previousSchool,
      'reason_for_leaving': app.reasonForLeaving,
      'results_file_name': app.resultsFileName,
    }) as Map<String, dynamic>;
    return _appFromJson(data);
  }

  Future<List<StudentApplication>> fetchApplications() async {
    final data = await _get('/applications/') as List;
    return data.map((d) => _appFromJson(d as Map<String, dynamic>)).toList();
  }

  Future<void> reviewApplication(String id) async {
    await _put('/applications/$id/review', {});
  }

  Future<void> deleteApplicationRemote(String id) async {
    await _delete('/applications/$id');
  }

  StudentApplication _appFromJson(Map<String, dynamic> d) {
    return StudentApplication(
      id: d['id'] as String,
      fullName: d['full_name'] as String,
      email: d['email'] as String,
      phone: d['phone'] as String,
      formApplyingFor: d['form_applying_for'] as String,
      previousSchool: d['previous_school'] as String,
      reasonForLeaving: d['reason_for_leaving'] as String,
      resultsFileName: d['results_file_name'] as String?,
      submittedAt: DateTime.parse(d['submitted_at'] as String),
      isReviewed: d['is_reviewed'] as bool? ?? false,
    );
  }
}
