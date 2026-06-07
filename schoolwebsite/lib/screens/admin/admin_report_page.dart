import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/stat_card.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  late TextEditingController _commentController;
  late TextEditingController _signatureController;
  String? _selectedClassId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = AppStateProvider.read(context);
    _commentController =
        TextEditingController(text: state.headmasterComment);
    _signatureController =
        TextEditingController(text: state.headmasterSignature);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final state = AppStateProvider.read(context);
    state.updateHeadmasterComment(_commentController.text);
    state.updateHeadmasterSignature(_signatureController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully.')),
    );
  }

  void _showReportPreview() {
    if (_selectedClassId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a class to generate a report.')),
      );
      return;
    }
    final state = AppStateProvider.read(context);
    final cls = state.classes.firstWhere((c) => c.id == _selectedClassId!);
    final students = state.getStudentsInClass(cls.id);

    // Subjects taught in this class
    final classTeacherIds = cls.teacherIds;
    final classSubjects = state.subjects
        .where((s) => classTeacherIds.contains(s.teacherId))
        .toList();

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: _ReportPreviewDialog(
          cls: cls,
          students: students,
          subjects: classSubjects,
          state: state,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppStateProvider.of(context); // listen for rebuilds

    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          const Text('Reports', style: AppTheme.heading1),
          const SizedBox(height: 4),
          const Text(
            'Configure headmaster comments and generate class reports.',
            style: AppTheme.label,
          ),
          const SizedBox(height: 28),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: settings ──────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Headmaster Comment',
                      subtitle:
                          'This comment will appear on every student report card.',
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: const Border.fromBorderSide(
                            BorderSide(color: AppTheme.border)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _commentController,
                            maxLines: 5,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Comment',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                              'Headmaster Signature Block',
                              style: AppTheme.heading3),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _signatureController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Name, Title, Institution',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _saveSettings,
                              child: const Text('Save Settings'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Generate report ─────────────────────────────────────
                    const SectionHeader(
                      title: 'Generate Class Report',
                      subtitle:
                          'Select a class and preview the printable report.',
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: const Border.fromBorderSide(
                            BorderSide(color: AppTheme.border)),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Select Class', style: AppTheme.heading3),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: const Border.fromBorderSide(
                                  BorderSide(color: AppTheme.border)),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedClassId,
                                isExpanded: true,
                                hint: const Text(
                                  'Choose a class',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                items: AppStateProvider.of(context).classes
                                    .map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c.id,
                                        child: Text(c.name,
                                            style: const TextStyle(
                                                fontSize: 14)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedClassId = v),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: _showReportPreview,
                              icon: const Icon(Icons.description_outlined,
                                  size: 16),
                              label: const Text('Preview Report'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'To print: use your browser\'s print function (Ctrl+P / Cmd+P).',
                            style: AppTheme.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // ── Right: note card ─────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Color(0xFFBAE6FD))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Information',
                        style: TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                          label: 'Academic Year', value: '2025 / 2026'),
                      _InfoRow(label: 'Term', value: 'Term 1'),
                      _InfoRow(
                          label: 'Institution',
                          value: 'Excellence High School'),
                      _InfoRow(
                          label: 'Headmaster',
                          value: AppStateProvider.of(context)
                              .headmasterSignature
                              .split('\n')
                              .first),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFBAE6FD)),
                      const SizedBox(height: 12),
                      const Text(
                        'Grading Scale',
                        style: TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _GradeRow(grade: 'A', range: '80 – 100'),
                      const _GradeRow(grade: 'B', range: '70 – 79'),
                      const _GradeRow(grade: 'C', range: '60 – 69'),
                      const _GradeRow(grade: 'D', range: '50 – 59'),
                      const _GradeRow(grade: 'F', range: 'Below 50'),
                      const SizedBox(height: 12),
                      const Text(
                        'Final = Term% × 40% + Exam% × 60%',
                        style: TextStyle(
                          color: Color(0xFF0369A1),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF0369A1), fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF075985),
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _GradeRow extends StatelessWidget {
  final String grade;
  final String range;
  const _GradeRow({required this.grade, required this.range});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.gradeBg(grade),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              grade,
              style: TextStyle(
                color: AppTheme.gradeColor(grade),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(range,
              style: const TextStyle(
                  color: Color(0xFF0369A1), fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Report preview dialog ─────────────────────────────────────────────────────

class _ReportPreviewDialog extends StatelessWidget {
  final dynamic cls;
  final List students;
  final List subjects;
  final dynamic state;

  const _ReportPreviewDialog({
    required this.cls,
    required this.students,
    required this.subjects,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 800,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Dialog title bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Report Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  'Use Ctrl+P to print',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Report content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // School header
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'EXCELLENCE HIGH SCHOOL',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Academic Results Report',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Academic Year: 2025/2026  |  Term 1',
                          style: AppTheme.caption,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryLight],
                            ),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Class info
                  Row(
                    children: [
                      _ReportMeta(label: 'Class', value: cls.name),
                      const SizedBox(width: 32),
                      _ReportMeta(
                          label: 'No. of Students',
                          value: '${students.length}'),
                      const SizedBox(width: 32),
                      _ReportMeta(
                          label: 'No. of Subjects',
                          value: '${subjects.length}'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Results table
                  _buildResultsTable(),

                  const SizedBox(height: 28),

                  // Headmaster comment
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Headmaster's Comment",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(state.headmasterComment,
                            style: const TextStyle(fontSize: 13, height: 1.6)),
                        const SizedBox(height: 16),
                        const Divider(color: AppTheme.border),
                        const SizedBox(height: 8),
                        const Text(
                          'Signature:',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          state.headmasterSignature,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTable() {
    if (subjects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No marks have been submitted for this class yet.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    // Columns: Student | Subject1 (Term%/Exam%/Grade) | ... | Avg | Grade
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 2,
                  child: Text('Student',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary)),
                ),
                ...subjects.map<Widget>((sub) => Expanded(
                      child: Text(
                        sub.name as String,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                const SizedBox(
                  width: 56,
                  child: Text('Avg',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary)),
                ),
                const SizedBox(
                  width: 40,
                  child: Text('Grade',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),
          // Rows
          ...students.asMap().entries.map((entry) {
            final student = entry.value;
            final isLast = entry.key == students.length - 1;

            final subjectData = subjects.map((sub) {
              final mark = state.getMark(student.id, sub.id);
              return (
                termPct: mark?.termPercentage,
                examPct: mark?.examPercentage,
                finalMark: mark?.finalMark,
                grade: mark?.grade,
              );
            }).toList();

            final withFinal = subjectData
                .where((d) => d.finalMark != null && d.finalMark! > 0)
                .map((d) => d.finalMark!)
                .toList();
            final avg = withFinal.isEmpty
                ? null
                : withFinal.reduce((a, b) => a + b) / withFinal.length;
            final String overallGrade;
            if (avg == null) {
              overallGrade = '—';
            } else if (avg >= 80) {
              overallGrade = 'A';
            } else if (avg >= 70) {
              overallGrade = 'B';
            } else if (avg >= 60) {
              overallGrade = 'C';
            } else if (avg >= 50) {
              overallGrade = 'D';
            } else {
              overallGrade = 'F';
            }

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: entry.key.isEven
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
                    flex: 2,
                    child: Text(student.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  ...subjectData.map<Widget>((d) => Expanded(
                        child: d.finalMark != null
                            ? Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'T:${d.termPct?.toStringAsFixed(0) ?? '—'}%'
                                    '  E:${d.examPct?.toStringAsFixed(0) ?? '—'}%',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: AppTheme.textSecondary),
                                  ),
                                  Text(
                                    d.grade ?? '—',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: d.grade != null
                                          ? AppTheme.gradeColor(d.grade!)
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : const Text('—',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary)),
                      )),
                  SizedBox(
                    width: 56,
                    child: Text(
                      avg != null ? avg.toStringAsFixed(1) : '—',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      overallGrade,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: overallGrade == '—'
                            ? AppTheme.textSecondary
                            : AppTheme.gradeColor(overallGrade),
                      ),
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

class _ReportMeta extends StatelessWidget {
  final String label;
  final String value;
  const _ReportMeta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
      ],
    );
  }
}
