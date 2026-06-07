import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/stat_card.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    final teachers = state.teachers;
    final submittedCount = state.submittedTeacherIds.length;
    final notSubmitted = teachers
        .where((t) => !state.submittedTeacherIds.contains(t.id))
        .toList();
    final totalStudents = state.students.length;
    final pendingApps = state.pendingApplicationsCount;
    final recentApps = state.applications
        .where((a) => !a.isReviewed)
        .take(5)
        .toList();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page header ──────────────────────────────────────────────────
          Text(
            'Welcome, ${state.currentUser?.name ?? 'Headmaster'}',
            style: AppTheme.heading1,
          ),
          const SizedBox(height: 4),
          const Text(
            'Academic Year 2025/2026  —  Term 1',
            style: AppTheme.label,
          ),
          const SizedBox(height: 28),

          // ── Stat cards ───────────────────────────────────────────────────
          if (isMobile) ...[
            Row(children: [
              Expanded(child: StatCard(label: 'Total Students', value: '$totalStudents', subtitle: 'Across all classes', accentColor: AppTheme.primaryLight)),
              const SizedBox(width: 12),
              Expanded(child: StatCard(label: 'Total Teachers', value: '${teachers.length}', subtitle: '${teachers.length} active', accentColor: const Color(0xFF0891B2))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: StatCard(label: 'Classes', value: '${state.classes.length}', subtitle: '${state.classes.length} active', accentColor: const Color(0xFF7C3AED))),
              const SizedBox(width: 12),
              Expanded(child: StatCard(label: 'Marks Submitted', value: '$submittedCount / ${teachers.length}', subtitle: 'teachers submitted', accentColor: submittedCount == teachers.length ? AppTheme.success : AppTheme.warning)),
            ]),
            const SizedBox(height: 12),
            StatCard(
              label: 'Applications',
              value: '$pendingApps',
              subtitle: 'pending review',
              accentColor: pendingApps > 0 ? const Color(0xFFF59E0B) : AppTheme.success,
            ),
          ] else
            Row(
              children: [
                Expanded(child: StatCard(label: 'Total Students', value: '$totalStudents', subtitle: 'Across all classes', accentColor: AppTheme.primaryLight)),
                const SizedBox(width: 16),
                Expanded(child: StatCard(label: 'Total Teachers', value: '${teachers.length}', subtitle: '${teachers.length} active', accentColor: const Color(0xFF0891B2))),
                const SizedBox(width: 16),
                Expanded(child: StatCard(label: 'Classes', value: '${state.classes.length}', subtitle: '${state.classes.length} active', accentColor: const Color(0xFF7C3AED))),
                const SizedBox(width: 16),
                Expanded(child: StatCard(label: 'Marks Submitted', value: '$submittedCount / ${teachers.length}', subtitle: 'teachers have submitted', accentColor: submittedCount == teachers.length ? AppTheme.success : AppTheme.warning)),
                const SizedBox(width: 16),
                Expanded(child: StatCard(label: 'Applications', value: '$pendingApps', subtitle: 'pending review', accentColor: pendingApps > 0 ? const Color(0xFFF59E0B) : AppTheme.success)),
              ],
            ),
          const SizedBox(height: 32),

          // ── Teacher submission status ────────────────────────────────────
          SectionHeader(
            title: 'Teacher Submission Status',
            subtitle: 'Shows which teachers have submitted marks for this term.',
          ),
          const SizedBox(height: 14),
          AppTable(
            headers: const ['TEACHER', 'SUBJECTS', 'CLASSES ASSIGNED', 'SUBMISSION STATUS'],
            rows: teachers.map((teacher) {
              final submitted = state.submittedTeacherIds.contains(teacher.id);
              final subjects = state.subjects
                  .where((s) => teacher.subjectIds.contains(s.id))
                  .map((s) => s.name)
                  .join(', ');
              final classes = state.classes
                  .where((c) => teacher.classIds.contains(c.id))
                  .map((c) => c.name)
                  .join(', ');
              return [
                Text(teacher.name, style: AppTheme.body),
                Text(subjects,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                Text(classes,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                StatusBadge(
                  label: submitted ? 'Submitted' : 'Not Submitted',
                  isPositive: submitted,
                ),
              ];
            }).toList(),
          ),

          // ── Pending alert ────────────────────────────────────────────────
          if (notSubmitted.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: const Border.fromBorderSide(
                    BorderSide(color: Color(0xFFFDE68A))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending Submissions',
                          style: TextStyle(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The following teachers have not yet submitted marks: '
                          '${notSubmitted.map((t) => t.name).join(', ')}.',
                          style: const TextStyle(
                              color: AppTheme.warning, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          // ── Quick class overview ─────────────────────────────────────────
          const SectionHeader(
            title: 'Class Overview',
            subtitle: 'Student count per class.',
          ),
          const SizedBox(height: 14),
          AppTable(
            headers: const ['CLASS', 'STUDENTS', 'ASSIGNED TEACHERS'],
            rows: state.classes.map((cls) {
              final assignedTeachers = state.teachers
                  .where((t) => t.classIds.contains(cls.id))
                  .map((t) => t.name)
                  .join(', ');
              final studentCount = state.getStudentsInClass(cls.id).length;
              return [
                Text(cls.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text('$studentCount',
                    style: AppTheme.body),
                Text(assignedTeachers,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
              ];
            }).toList(),
          ),
          const SizedBox(height: 32),

          // ── Pending applications preview ──────────────────────────────────
          SectionHeader(
            title: 'Pending Applications',
            subtitle: 'Recent admissions applications awaiting review. Go to Applications for full details.',
          ),
          const SizedBox(height: 14),
          if (recentApps.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.success, size: 20),
                  SizedBox(width: 10),
                  Text('No pending applications.',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            )
          else
            AppTable(
              headers: const ['APPLICANT', 'FORM', 'CONTACT', 'PREVIOUS SCHOOL', 'SUBMITTED'],
              rows: recentApps.map((app) {
                final months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
                final d = app.submittedAt;
                final date = '${d.day} ${months[d.month - 1]}';
                return [
                  Text(app.fullName, style: AppTheme.body),
                  Text(app.formApplyingFor,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  Text(app.phone,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  Text(app.previousSchool,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  Text(date,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ];
              }).toList(),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
