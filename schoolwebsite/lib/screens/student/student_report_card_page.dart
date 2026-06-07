import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/stat_card.dart';

class StudentReportCardPage extends StatelessWidget {
  const StudentReportCardPage({super.key});

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

    final classSubjects = state.subjects
        .where((s) => classGroup.teacherIds.contains(s.teacherId))
        .toList();

    final marksWithData = classSubjects
        .map((s) {
          final m = state.getMark(studentId, s.id);
          return m != null ? (subject: s, mark: m) : null;
        })
        .whereType<({Subject subject, Mark mark})>()
        .toList();

    final finalMarks =
        marksWithData.map((e) => e.mark.finalMark).toList();
    final average = finalMarks.isEmpty
        ? 0.0
        : finalMarks.reduce((a, b) => a + b) / finalMarks.length;
    final overallGrade = finalMarks.isEmpty
        ? '—'
        : average >= 80
            ? 'A'
            : average >= 70
                ? 'B'
                : average >= 60
                    ? 'C'
                    : average >= 50
                        ? 'D'
                        : 'F';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Report Card', style: AppTheme.heading1),
          const SizedBox(height: 4),
          const Text(
            'Your official academic report for this term.',
            style: AppTheme.label,
          ),
          const SizedBox(height: 28),

          // ── Report card container ────────────────────────────────────────
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: const Border.fromBorderSide(
                      BorderSide(color: AppTheme.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header band ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'EXCELLENCE HIGH SCHOOL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'STUDENT ACADEMIC REPORT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Academic Year 2025/2026  |  Term 1',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 20),
                          // Student info row
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _HeaderField(
                                  label: 'Student Name',
                                  value: student.name),
                              _HeaderField(
                                  label: 'Class',
                                  value: classGroup.name),
                              _HeaderField(
                                  label: 'Student ID',
                                  value: student.id.toUpperCase()),
                              if (finalMarks.isNotEmpty)
                                _HeaderField(
                                  label: 'Overall Grade',
                                  value: overallGrade,
                                  valueColor:
                                      AppTheme.gradeColor(overallGrade),
                                  valueBg:
                                      AppTheme.gradeBg(overallGrade),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Marks table ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Academic Performance',
                            style: AppTheme.heading3,
                          ),
                          const SizedBox(height: 12),

                          if (marksWithData.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: const Border.fromBorderSide(
                                    BorderSide(color: AppTheme.border)),
                              ),
                              child: const Center(
                                child: Text(
                                  'Marks for this term have not been entered yet.',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14),
                                ),
                              ),
                            )
                          else
                            _MarksTable(marksWithData: marksWithData),

                          if (marksWithData.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _SummaryBar(
                              average: average,
                              overallGrade: overallGrade,
                              passingCount: finalMarks
                                  .where((f) => f >= 50)
                                  .length,
                              total: finalMarks.length,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const Divider(height: 1, color: AppTheme.border),

                    // ── Headmaster comment ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Headmaster's Comment",
                            style: AppTheme.heading3,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: const Border.fromBorderSide(
                                  BorderSide(color: AppTheme.border)),
                            ),
                            child: Text(
                              state.headmasterComment,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.7,
                                color: AppTheme.textPrimary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Signature block
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Headmaster\'s Signature',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 180,
                                      height: 1,
                                      color: AppTheme.textPrimary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.headmasterSignature,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        height: 1.6,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Official stamp simulation
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'OFFICIAL',
                                      style: TextStyle(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.5),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    Text(
                                      'SEAL',
                                      style: TextStyle(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.5),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Footer ────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(8)),
                        border: Border(
                            top: BorderSide(color: AppTheme.border)),
                      ),
                      child: const Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Excellence High School  |  Results Management Portal',
                            style: AppTheme.caption,
                          ),
                          Text(
                            'Grading: A(80+)  B(70-79)  C(60-69)  D(50-59)  F(<50)',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeaderField extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color? valueBg;

  const _HeaderField({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        valueBg != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: valueBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ],
    );
  }
}

class _MarksTable extends StatelessWidget {
  final List<({Subject subject, Mark mark})> marksWithData;

  const _MarksTable({required this.marksWithData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: const Border.fromBorderSide(BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              border:
                  Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _TH('SUBJECT')),
                Expanded(child: _TH('TERM %\n(40%)')),
                Expanded(child: _TH('EXAM %\n(60%)')),
                Expanded(child: _TH('FINAL')),
                SizedBox(width: 60, child: _TH('GRADE')),
                SizedBox(width: 70, child: _TH('STATUS')),
              ],
            ),
          ),
          // Rows
          ...marksWithData.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final isLast = i == marksWithData.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: i.isEven
                    ? AppTheme.surface
                    : const Color(0xFFFAFAFA),
                borderRadius: isLast
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(6))
                    : null,
                border: !isLast
                    ? const Border(
                        bottom: BorderSide(color: AppTheme.border))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.subject.name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${e.mark.termPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${e.mark.examPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.mark.finalMark.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: GradeBadge(grade: e.mark.grade),
                  ),
                  SizedBox(
                    width: 70,
                    child: StatusBadge(
                      label: e.mark.isPassing ? 'Pass' : 'Fail',
                      isPositive: e.mark.isPassing,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String text;
  const _TH(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final double average;
  final String overallGrade;
  final int passingCount;
  final int total;

  const _SummaryBar({
    required this.average,
    required this.overallGrade,
    required this.passingCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.gradeBg(overallGrade),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
                label: 'Term Average',
                value: average.toStringAsFixed(1)),
          ),
          Expanded(
            child: _SummaryItem(
                label: 'Overall Grade', value: overallGrade),
          ),
          Expanded(
            child: _SummaryItem(
                label: 'Subjects Passed',
                value: '$passingCount / $total'),
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Pass Rate',
              value:
                  '${((passingCount / total) * 100).toStringAsFixed(0)}%',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
      ],
    );
  }
}
