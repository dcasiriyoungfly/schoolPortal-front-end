import 'package:schoolwebsite/models/models.dart';

// ─── Users ───────────────────────────────────────────────────────────────────

const List<AppUser> mockUsers = [
  AppUser(id: '5829A', name: 'Admin', role: UserRole.admin, password: 'admin123'),
];

// ─── Teachers ────────────────────────────────────────────────────────────────

const List<Teacher> mockTeachers = [];

// ─── Subjects ─────────────────────────────────────────────────────────────────

const List<Subject> mockSubjects = [
  Subject(id: 'sub1', name: 'Mathematics', teacherId: ''),
  Subject(id: 'sub2', name: 'Science', teacherId: ''),
  Subject(id: 'sub3', name: 'English', teacherId: ''),
  Subject(id: 'sub4', name: 'History', teacherId: ''),
  Subject(id: 'sub5', name: 'Geography', teacherId: ''),
  Subject(id: 'sub6', name: 'Civic Education', teacherId: ''),
  Subject(id: 'sub7', name: 'Biology', teacherId: ''),
  Subject(id: 'sub8', name: 'Chemistry', teacherId: ''),
];

// ─── Classes ─────────────────────────────────────────────────────────────────

const List<ClassGroup> mockClasses = [
  ClassGroup(
    id: 'c1',
    name: 'Form 3A',
    studentIds: [],
    teacherIds: [],
  ),
  ClassGroup(
    id: 'c2',
    name: 'Form 3B',
    studentIds: [],
    teacherIds: [],
  ),
  ClassGroup(
    id: 'c3',
    name: 'Form 4A',
    studentIds: [],
    teacherIds: [],
  ),
  ClassGroup(
    id: 'c4',
    name: 'Form 4B',
    studentIds: [],
    teacherIds: [],
  ),
];

// ─── Students ─────────────────────────────────────────────────────────────────

const List<Student> mockStudents = [];

// ─── Initial Marks ────────────────────────────────────────────────────────────

Mark _m(String sid, String subid, String cid, double termPct, double examPct) =>
    Mark(studentId: sid, subjectId: subid, classId: cid, termPercentage: termPct, examPercentage: examPct);

List<Mark> get initialMarks => [];

// Teachers who have already submitted marks
const Set<String> initialSubmittedTeacherIds = {};
