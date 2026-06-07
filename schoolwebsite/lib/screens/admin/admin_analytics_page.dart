import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/stat_card.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final topTeacherId = state.getHighestPerformingTeacherId();

    // Compute pass rates for all teachers
    final rateData = state.teachers.map((t) {
      return (teacher: t, rate: state.getPassRate(t.id));
    }).toList();

    // Average pass rate (only teachers with marks)
    final submitted = rateData.where((d) => d.rate >= 0).toList();
    final avgRate = submitted.isEmpty
        ? 0.0
        : submitted.map((d) => d.rate).reduce((a, b) => a + b) /
            submitted.length;

    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          const Text('Analytics', style: AppTheme.heading1),
          const SizedBox(height: 4),
          const Text(
            'Performance overview based on submitted marks.',
            style: AppTheme.label,
          ),
          const SizedBox(height: 28),

          // ── Summary stats ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'School Pass Rate',
                  value: submitted.isEmpty
                      ? 'N/A'
                      : '${avgRate.toStringAsFixed(1)}%',
                  subtitle: 'Average across submitted marks',
                  accentColor: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Teachers Submitted',
                  value: '${submitted.length} / ${state.teachers.length}',
                  subtitle: 'Data completeness',
                  accentColor: submitted.length == state.teachers.length
                      ? AppTheme.success
                      : AppTheme.warning,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Top Performer',
                  value: topTeacherId != null
                      ? state.teachers
                          .firstWhere((t) => t.id == topTeacherId)
                          .name
                          .split(' ')
                          .last
                      : 'N/A',
                  subtitle: topTeacherId != null
                      ? '${state.getPassRate(topTeacherId).toStringAsFixed(1)}% pass rate'
                      : 'No data yet',
                  accentColor: AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Bar chart ─────────────────────────────────────────────────────
          const SectionHeader(
            title: 'Pass Rate by Teacher',
            subtitle: 'Percentage of students scoring 50 marks or above.',
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
              children: rateData.map((data) {
                final isTop = data.teacher.id == topTeacherId;
                final hasData = data.rate >= 0;
                final rate = hasData ? data.rate : 0.0;
                final barColor = isTop
                    ? AppTheme.success
                    : rate >= 70
                        ? AppTheme.primaryLight
                        : rate >= 50
                            ? AppTheme.warning
                            : AppTheme.error;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Text(
                                  data.teacher.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isTop
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (isTop) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'TOP',
                                      style: TextStyle(
                                        color: AppTheme.success,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            hasData
                                ? '${rate.toStringAsFixed(1)}%'
                                : 'No data',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: hasData
                                  ? barColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              Container(
                                height: 10,
                                width: constraints.maxWidth,
                                decoration: BoxDecoration(
                                  color: AppTheme.border,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOut,
                                height: 10,
                                width: constraints.maxWidth * (rate / 100),
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(5),
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
          const SizedBox(height: 32),

          // ── Detailed table ────────────────────────────────────────────────
          const SectionHeader(
            title: 'Detailed Performance Table',
            subtitle: 'Subject-level statistics per teacher.',
          ),
          const SizedBox(height: 14),
          AppTable(
            headers: const [
              'TEACHER',
              'SUBJECTS',
              'PASS RATE',
              'STATUS',
            ],
            rows: rateData.map((data) {
              final hasData = data.rate >= 0;
              final isTop = data.teacher.id == topTeacherId;
              final subjects = state.subjects
                  .where((s) => data.teacher.subjectIds.contains(s.id))
                  .map((s) => s.name)
                  .join(', ');

              return [
                Row(
                  children: [
                    Text(
                      data.teacher.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isTop ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (isTop) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successBg,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'HIGHEST',
                          style: TextStyle(
                            color: AppTheme.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(subjects,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                Text(
                  hasData ? '${data.rate.toStringAsFixed(1)}%' : '—',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasData
                        ? (data.rate >= 70
                            ? AppTheme.success
                            : data.rate >= 50
                                ? AppTheme.warning
                                : AppTheme.error)
                        : AppTheme.textSecondary,
                  ),
                ),
                StatusBadge(
                  label: hasData ? 'Submitted' : 'Pending',
                  isPositive: hasData,
                ),
              ];
            }).toList(),
          ),

          const SizedBox(height: 32),
          // ── Grade legend ──────────────────────────────────────────────────
          const SectionHeader(title: 'Grading System Reference'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _GradeRef(grade: 'A', range: '80 – 100', meaning: 'Distinction'),
              _GradeRef(grade: 'B', range: '70 – 79', meaning: 'Merit'),
              _GradeRef(grade: 'C', range: '60 – 69', meaning: 'Credit'),
              _GradeRef(grade: 'D', range: '50 – 59', meaning: 'Pass'),
              _GradeRef(grade: 'F', range: 'Below 50', meaning: 'Fail'),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _GradeRef extends StatelessWidget {
  final String grade;
  final String range;
  final String meaning;

  const _GradeRef(
      {required this.grade, required this.range, required this.meaning});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.gradeBg(grade),
        borderRadius: BorderRadius.circular(6),
        border: Border.fromBorderSide(
            BorderSide(color: AppTheme.gradeColor(grade).withValues(alpha: 0.3))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            grade,
            style: TextStyle(
              color: AppTheme.gradeColor(grade),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                range,
                style: TextStyle(
                  color: AppTheme.gradeColor(grade),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                meaning,
                style: TextStyle(
                  color: AppTheme.gradeColor(grade).withValues(alpha: 0.75),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
