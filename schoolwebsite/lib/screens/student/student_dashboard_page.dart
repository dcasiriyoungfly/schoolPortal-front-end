import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/stat_card.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final studentId = state.currentUser?.linkedId ?? '';

    final student = state.getStudent(studentId);
    if (student == null) {
      return const Center(child: Text('Student record not found.'));
    }

    final classGroup = state.classes.firstWhere(
      (c) => c.id == student.classId,
      orElse: () =>
          const ClassGroup(id: '', name: '', studentIds: [], teacherIds: []),
    );

    // Subjects available in this class
    final classSubjects = state.subjects
        .where((s) => classGroup.teacherIds.contains(s.teacherId))
        .toList();

    final marksWithData = classSubjects
        .map((s) {
          final m = state.getMark(studentId, s.id);
          return m != null ? (subject: s, mark: m) : null;
        })
        .whereType<({Subject subject, dynamic mark})>()
        .toList();

    final finalMarks =
        marksWithData.map<double>((e) => e.mark.finalMark as double).toList();
    final average = finalMarks.isEmpty
        ? 0.0
        : finalMarks.reduce((a, b) => a + b) / finalMarks.length;

    final overallGrade = average >= 80
        ? 'A'
        : average >= 70
            ? 'B'
            : average >= 60
                ? 'C'
                : average >= 50
                    ? 'D'
                    : finalMarks.isEmpty
                        ? '—'
                        : 'F';

    final passingCount =
        finalMarks.where((f) => f >= 50).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Text(
            'Welcome, ${student.name}',
            style: AppTheme.heading1,
          ),
          const SizedBox(height: 4),
          Text(
            '${classGroup.name}  —  Academic Year 2025/2026  —  Term 1',
            style: AppTheme.label,
          ),
          const SizedBox(height: 28),

          // ── Stat cards ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Subjects',
                  value: '${classSubjects.length}',
                  subtitle: 'Enrolled this term',
                  accentColor: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Marks Available',
                  value: '${marksWithData.length}',
                  subtitle: 'of ${classSubjects.length} subjects',
                  accentColor: const Color(0xFF0891B2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Term Average',
                  value: finalMarks.isEmpty
                      ? 'N/A'
                      : average.toStringAsFixed(1),
                  subtitle: finalMarks.isEmpty
                      ? 'No marks yet'
                      : 'Overall grade: $overallGrade',
                  accentColor: finalMarks.isEmpty
                      ? AppTheme.textSecondary
                      : AppTheme.gradeColor(overallGrade),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Subjects Passed',
                  value: '$passingCount / ${marksWithData.length}',
                  subtitle: marksWithData.isEmpty
                      ? 'No data yet'
                      : passingCount == marksWithData.length
                          ? 'All subjects passed'
                          : '${marksWithData.length - passingCount} need improvement',
                  accentColor: passingCount == marksWithData.length &&
                          marksWithData.isNotEmpty
                      ? AppTheme.success
                      : AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Results summary table ────────────────────────────────────────
          const SectionHeader(
            title: 'My Results Summary',
            subtitle: 'Current term marks across all subjects.',
          ),
          const SizedBox(height: 14),

          if (marksWithData.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: const Border.fromBorderSide(
                    BorderSide(color: AppTheme.border)),
              ),
              child: const Center(
                child: Text(
                  'Your marks have not been entered yet. Please check back later.',
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 14),
                ),
              ),
            )
          else
            AppTable(
              headers: const [
                'SUBJECT',
                'TERM %',
                'EXAM %',
                'FINAL MARK',
                'GRADE',
                'STATUS',
              ],
              rows: marksWithData.map((e) {
                final mark = e.mark;
                return [
                  Text(e.subject.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  Text('${mark.termPercentage.toStringAsFixed(1)}%',
                      style: AppTheme.body),
                  Text('${mark.examPercentage.toStringAsFixed(1)}%',
                      style: AppTheme.body),
                  Text(
                    mark.finalMark.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  GradeBadge(grade: mark.grade),
                  StatusBadge(
                    label: mark.isPassing ? 'Pass' : 'Fail',
                    isPositive: mark.isPassing,
                  ),
                ];
              }).toList(),
            ),

          if (marksWithData.isNotEmpty) ...[
            const SizedBox(height: 32),
            // ── Performance indicator ─────────────────────────────────────
            const SectionHeader(
              title: 'Subject Performance',
              subtitle: 'Visual breakdown of final marks per subject.',
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: const Border.fromBorderSide(
                    BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                children: marksWithData.map((e) {
                  final pct = e.mark.finalMark / 100;
                  final color = AppTheme.gradeColor(e.mark.grade);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.subject.name,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${e.mark.finalMark.toStringAsFixed(1)}%  (${e.mark.grade})',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Container(
                                  height: 8,
                                  width: constraints.maxWidth,
                                  decoration: BoxDecoration(
                                    color: AppTheme.border,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  height: 8,
                                  width: constraints.maxWidth * pct,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
