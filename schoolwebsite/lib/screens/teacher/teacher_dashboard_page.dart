import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/stat_card.dart';

class TeacherDashboardPage extends StatelessWidget {
  const TeacherDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final teacherId = state.currentUser?.linkedId ?? '';

    final teacher = state.teachers.firstWhere(
      (t) => t.id == teacherId,
      orElse: () =>
          const Teacher(id: '', name: '', subjectIds: [], classIds: []),
    );

    final subjects = state.subjects
        .where((s) => teacher.subjectIds.contains(s.id))
        .toList();
    final classes = state.classes
        .where((c) => teacher.classIds.contains(c.id))
        .toList();

    final totalStudents = classes
        .fold<int>(0, (sum, c) => sum + c.studentIds.length);

    final hasSubmitted = state.submittedTeacherIds.contains(teacherId);

    // Per-class submission state: check if marks exist for this teacher's subjects
    final classSubmission = {
      for (final cls in classes)
        cls.id: _classHasMarks(state, cls, teacher),
    };

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Text(
            'Welcome, ${state.currentUser?.name ?? 'Teacher'}',
            style: AppTheme.heading1,
          ),
          const SizedBox(height: 4),
          const Text(
            'Academic Year 2025/2026  —  Term 1',
            style: AppTheme.label,
          ),
          const SizedBox(height: 20),

          // Submission status banner
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasSubmitted ? AppTheme.successBg : AppTheme.warningBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.fromBorderSide(BorderSide(
                color: hasSubmitted
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFFDE68A),
              )),
            ),
            child: Row(
              children: [
                Icon(
                  hasSubmitted
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  size: 18,
                  color: hasSubmitted ? AppTheme.success : AppTheme.warning,
                ),
                const SizedBox(width: 10),
                Text(
                  hasSubmitted
                      ? 'Your marks have been submitted for this term.'
                      : 'Marks have not been submitted yet. Go to Marks Entry to submit.',
                  style: TextStyle(
                    color: hasSubmitted ? AppTheme.success : AppTheme.warning,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Stat cards ───────────────────────────────────────────────────
          if (isMobile) ...[
            StatCard(label: 'Assigned Subjects', value: '${subjects.length}', subtitle: subjects.map((s) => s.name).join(', '), accentColor: AppTheme.primaryLight),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: StatCard(label: 'Assigned Classes', value: '${classes.length}', subtitle: classes.map((c) => c.name).join(', '), accentColor: const Color(0xFF7C3AED))),
              const SizedBox(width: 12),
              Expanded(child: StatCard(label: 'Total Students', value: '$totalStudents', subtitle: 'Across all your classes', accentColor: const Color(0xFF0891B2))),
            ]),
          ] else
            Row(
              children: [
                Expanded(child: StatCard(label: 'Assigned Subjects', value: '${subjects.length}', subtitle: subjects.map((s) => s.name).join(', '), accentColor: AppTheme.primaryLight)),
                const SizedBox(width: 16),
                Expanded(child: StatCard(label: 'Assigned Classes', value: '${classes.length}', subtitle: classes.map((c) => c.name).join(', '), accentColor: const Color(0xFF7C3AED))),
                const SizedBox(width: 16),
                Expanded(child: StatCard(label: 'Total Students', value: '$totalStudents', subtitle: 'Across all your classes', accentColor: const Color(0xFF0891B2))),
              ],
            ),
          const SizedBox(height: 32),

          // ── Subjects table ───────────────────────────────────────────────
          const SectionHeader(
            title: 'My Subjects',
            subtitle: 'Subjects you are responsible for this term.',
          ),
          const SizedBox(height: 14),
          AppTable(
            headers: const ['SUBJECT', 'SUBJECT ID', 'STATUS'],
            rows: subjects.map((sub) {
              return [
                Text(sub.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text(sub.id,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                StatusBadge(
                  label: hasSubmitted ? 'Submitted' : 'Pending',
                  isPositive: hasSubmitted,
                ),
              ];
            }).toList(),
          ),
          const SizedBox(height: 28),

          // ── Classes overview ─────────────────────────────────────────────
          const SectionHeader(
            title: 'My Classes',
            subtitle: 'Classes and their marks submission status.',
          ),
          const SizedBox(height: 14),
          AppTable(
            headers: const ['CLASS', 'STUDENTS', 'MARKS STATUS'],
            rows: classes.map((cls) {
              final marksIn = classSubmission[cls.id] ?? false;
              return [
                Text(cls.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text('${cls.studentIds.length}', style: AppTheme.body),
                StatusBadge(
                  label: marksIn ? 'Marks Entered' : 'Not Entered',
                  isPositive: marksIn,
                ),
              ];
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  bool _classHasMarks(dynamic state, ClassGroup cls, Teacher teacher) {
    if (cls.studentIds.isEmpty || teacher.subjectIds.isEmpty) return false;
    // Check if at least one student in this class has a mark in a teacher subject
    for (final studentId in cls.studentIds) {
      for (final subjectId in teacher.subjectIds) {
        if (state.getMark(studentId, subjectId) != null) return true;
      }
    }
    return false;
  }
}
