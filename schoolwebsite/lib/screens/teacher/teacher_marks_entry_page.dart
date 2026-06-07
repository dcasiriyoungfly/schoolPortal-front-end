import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/stat_card.dart';

class TeacherMarksEntryPage extends StatefulWidget {
  const TeacherMarksEntryPage({super.key});

  @override
  State<TeacherMarksEntryPage> createState() => _TeacherMarksEntryPageState();
}

class _TeacherMarksEntryPageState extends State<TeacherMarksEntryPage> {
  String? _selectedClassId;
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final teacherId = state.currentUser?.linkedId ?? '';

    final teacher = state.getTeacher(teacherId) ??
        const Teacher(id: '', name: '', subjectIds: [], classIds: []);

    final teacherClasses =
        state.classes.where((c) => teacher.classIds.contains(c.id)).toList();
    final teacherSubjects =
        state.subjects.where((s) => teacher.subjectIds.contains(s.id)).toList();

    final canShowTable =
        _selectedClassId != null && _selectedSubjectId != null;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Marks Entry', style: AppTheme.heading1),
          const SizedBox(height: 4),
          const Text(
            'Select a class and subject, then add term tests and exam components.',
            style: AppTheme.label,
          ),
          const SizedBox(height: 28),

          // ── Selectors ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: const Border.fromBorderSide(
                  BorderSide(color: AppTheme.border)),
            ),
            child: teacherClasses.isEmpty && teacherSubjects.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'You have no classes or subjects assigned yet. '
                      'Please contact the administrator.',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Class', style: AppTheme.heading3),
                            const SizedBox(height: 8),
                            _Dropdown(
                              value: _selectedClassId,
                              hint: 'Select class',
                              items: teacherClasses
                                  .map((c) => DropdownMenuItem(
                                      value: c.id, child: Text(c.name)))
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _selectedClassId = v;
                                _selectedSubjectId = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Subject', style: AppTheme.heading3),
                            const SizedBox(height: 8),
                            _Dropdown(
                              value: _selectedSubjectId,
                              hint: 'Select subject',
                              items: teacherSubjects
                                  .map((s) => DropdownMenuItem(
                                      value: s.id, child: Text(s.name)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedSubjectId = v),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),

          if (!canShowTable)
            _placeholder('Select a class and subject above to load the mark sheet.')
          else
            _MarksSection(
              key: ValueKey('$_selectedClassId:$_selectedSubjectId'),
              classId: _selectedClassId!,
              subjectId: _selectedSubjectId!,
              teacherId: teacherId,
            ),
        ],
      ),
    );
  }

  Widget _placeholder(String msg) => Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: const Border.fromBorderSide(BorderSide(color: AppTheme.border)),
        ),
        child: Center(
          child: Text(msg,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Main marks section — owns config, controllers, save logic
// ─────────────────────────────────────────────────────────────────────────────

class _MarksSection extends StatefulWidget {
  final String classId;
  final String subjectId;
  final String teacherId;

  const _MarksSection({
    super.key,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
  });

  @override
  State<_MarksSection> createState() => _MarksSectionState();
}

class _MarksSectionState extends State<_MarksSection> {
  List<Student> _students = [];
  MarkConfig? _config;
  String _className = '';
  String _subjectName = '';
  bool _isLoading = true;

  // save state: 0=idle, 1=saving, 2=success, 3=error
  int _saveState = 0;

  // studentId → componentId → controller / focus node
  final Map<String, Map<String, TextEditingController>> _termCtrls = {};
  final Map<String, Map<String, TextEditingController>> _examCtrls = {};
  final Map<String, TextEditingController> _nameCtrls = {};
  final Map<String, Map<String, FocusNode>> _termFocus = {};
  final Map<String, Map<String, FocusNode>> _examFocus = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final m in _termCtrls.values) {
      for (final c in m.values) { c.dispose(); }
    }
    for (final m in _examCtrls.values) {
      for (final c in m.values) { c.dispose(); }
    }
    for (final c in _nameCtrls.values) { c.dispose(); }
    for (final m in _termFocus.values) {
      for (final n in m.values) { n.dispose(); }
    }
    for (final m in _examFocus.values) {
      for (final n in m.values) { n.dispose(); }
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final state = AppStateProvider.read(context);
    _students = state.getStudentsInClass(widget.classId);
    _className = state.classes
        .firstWhere((c) => c.id == widget.classId,
            orElse: () => ClassGroup(
                id: '', name: widget.classId, studentIds: [], teacherIds: []))
        .name;
    _subjectName = state.subjects
        .firstWhere((s) => s.id == widget.subjectId,
            orElse: () =>
                Subject(id: '', name: widget.subjectId, teacherId: ''))
        .name;

    MarkConfig config;
    try {
      config = await state.fetchMarkConfig(widget.subjectId, widget.classId);
    } catch (_) {
      config = MarkConfig(subjectId: widget.subjectId, classId: widget.classId);
    }

    for (final student in _students) {
      _nameCtrls[student.id] = TextEditingController(text: student.name);
      _termCtrls[student.id] = {};
      _examCtrls[student.id] = {};
      _termFocus[student.id] = {};
      _examFocus[student.id] = {};

      final mark = state.getMark(student.id, widget.subjectId);

      for (final comp in config.termComponents) {
        final entry = mark?.termEntries
            .where((e) => e.componentId == comp.id)
            .firstOrNull;
        final ctrl = TextEditingController(
            text: entry != null ? entry.mark.toStringAsFixed(0) : '');
        ctrl.addListener(() => setState(() {}));
        _termCtrls[student.id]![comp.id] = ctrl;
        _termFocus[student.id]![comp.id] = FocusNode();
      }

      for (final comp in config.examComponents) {
        final entry = mark?.examEntries
            .where((e) => e.componentId == comp.id)
            .firstOrNull;
        final ctrl = TextEditingController(
            text: entry != null ? entry.mark.toStringAsFixed(0) : '');
        ctrl.addListener(() => setState(() {}));
        _examCtrls[student.id]![comp.id] = ctrl;
        _examFocus[student.id]![comp.id] = FocusNode();
      }
    }

    if (mounted) setState(() { _config = config; _isLoading = false; });
  }

  // ── Add / remove components ─────────────────────────────────────────────────

  Future<void> _addComponent(bool isTerm) async {
    final result = await showDialog<({String name, double maxMark})>(
      context: context,
      builder: (_) => const _AddComponentDialog(),
    );
    if (result == null || !mounted) return;

    final id = 'comp_${DateTime.now().millisecondsSinceEpoch}';
    final newComp =
        MarkComponent(id: id, name: result.name, maxMark: result.maxMark);
    final cfg = _config!;
    final newConfig = cfg.copyWith(
      termComponents:
          isTerm ? [...cfg.termComponents, newComp] : cfg.termComponents,
      examComponents:
          isTerm ? cfg.examComponents : [...cfg.examComponents, newComp],
    );

    await AppStateProvider.read(context).saveMarkConfig(newConfig);

    for (final student in _students) {
      final ctrl = TextEditingController();
      ctrl.addListener(() => setState(() {}));
      if (isTerm) {
        _termCtrls[student.id]![id] = ctrl;
        _termFocus[student.id]![id] = FocusNode();
      } else {
        _examCtrls[student.id]![id] = ctrl;
        _examFocus[student.id]![id] = FocusNode();
      }
    }

    if (mounted) setState(() => _config = newConfig);
  }

  Future<void> _removeComponent(String compId, bool isTerm) async {
    final cfg = _config!;
    final newConfig = cfg.copyWith(
      termComponents: isTerm
          ? cfg.termComponents.where((c) => c.id != compId).toList()
          : cfg.termComponents,
      examComponents: isTerm
          ? cfg.examComponents
          : cfg.examComponents.where((c) => c.id != compId).toList(),
    );

    await AppStateProvider.read(context).saveMarkConfig(newConfig);

    for (final student in _students) {
      if (isTerm) {
        _termCtrls[student.id]?[compId]?.dispose();
        _termCtrls[student.id]?.remove(compId);
        _termFocus[student.id]?[compId]?.dispose();
        _termFocus[student.id]?.remove(compId);
      } else {
        _examCtrls[student.id]?[compId]?.dispose();
        _examCtrls[student.id]?.remove(compId);
        _examFocus[student.id]?[compId]?.dispose();
        _examFocus[student.id]?.remove(compId);
      }
    }

    if (mounted) setState(() => _config = newConfig);
  }

  // ── Percentage helpers ──────────────────────────────────────────────────────

  double _termPct(String studentId) {
    final cfg = _config;
    if (cfg == null || cfg.termComponents.isEmpty) return 0.0;
    final totalMax =
        cfg.termComponents.fold(0.0, (s, c) => s + c.maxMark);
    if (totalMax <= 0) return 0.0;
    double total = 0;
    for (final comp in cfg.termComponents) {
      final val = double.tryParse(
              _termCtrls[studentId]?[comp.id]?.text.trim() ?? '') ??
          0.0;
      total += val.clamp(0, comp.maxMark);
    }
    return (total / totalMax) * 100;
  }

  double _examPct(String studentId) {
    final cfg = _config;
    if (cfg == null || cfg.examComponents.isEmpty) return 0.0;
    final totalMax =
        cfg.examComponents.fold(0.0, (s, c) => s + c.maxMark);
    if (totalMax <= 0) return 0.0;
    double total = 0;
    for (final comp in cfg.examComponents) {
      final val = double.tryParse(
              _examCtrls[studentId]?[comp.id]?.text.trim() ?? '') ??
          0.0;
      total += val.clamp(0, comp.maxMark);
    }
    return (total / totalMax) * 100;
  }

  bool _hasTermData(String studentId) => _config?.termComponents.any((c) {
        final t = _termCtrls[studentId]?[c.id]?.text.trim() ?? '';
        return t.isNotEmpty && double.tryParse(t) != null;
      }) ??
      false;

  bool _hasExamData(String studentId) => _config?.examComponents.any((c) {
        final t = _examCtrls[studentId]?[c.id]?.text.trim() ?? '';
        return t.isNotEmpty && double.tryParse(t) != null;
      }) ??
      false;

  String _grade(double final_) {
    if (final_ >= 80) return 'A';
    if (final_ >= 70) return 'B';
    if (final_ >= 60) return 'C';
    if (final_ >= 50) return 'D';
    return 'F';
  }

  // ── Save (all students in parallel) ────────────────────────────────────────

  Future<void> _save() async {
    if (_saveState == 1) return;
    setState(() => _saveState = 1);
    final state = AppStateProvider.read(context);
    final cfg = _config!;
    bool hasErrors = false;

    final futures = <Future<void>>[];

    for (final student in _students) {
      final newName = _nameCtrls[student.id]?.text.trim() ?? '';
      if (newName.isNotEmpty && newName != student.name) {
        futures.add(state.updateStudentName(student.id, newName));
      }

      final termEntries = <MarkEntry>[];
      for (final comp in cfg.termComponents) {
        final text = _termCtrls[student.id]?[comp.id]?.text.trim() ?? '';
        if (text.isEmpty) continue;
        final val = double.tryParse(text);
        if (val == null || val < 0 || val > comp.maxMark) { hasErrors = true; continue; }
        termEntries.add(MarkEntry(componentId: comp.id, mark: val));
      }

      final examEntries = <MarkEntry>[];
      for (final comp in cfg.examComponents) {
        final text = _examCtrls[student.id]?[comp.id]?.text.trim() ?? '';
        if (text.isEmpty) continue;
        final val = double.tryParse(text);
        if (val == null || val < 0 || val > comp.maxMark) { hasErrors = true; continue; }
        examEntries.add(MarkEntry(componentId: comp.id, mark: val));
      }

      if (termEntries.isNotEmpty || examEntries.isNotEmpty) {
        futures.add(state.upsertMark(Mark(
          studentId: student.id,
          subjectId: widget.subjectId,
          classId: widget.classId,
          termEntries: termEntries,
          examEntries: examEntries,
        )));
      }
    }

    try {
      await Future.wait(futures);
      await state.markTeacherSubmitted(widget.teacherId);
      if (!mounted) return;
      setState(() => _saveState = 2);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _saveState = 0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveState = 3);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) setState(() => _saveState = 0);
    }

    if (!mounted) return;
    if (hasErrors) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Some values exceeded the maximum and were skipped.'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  // ── Download ────────────────────────────────────────────────────────────────

  String _buildHtmlReport() {
    final cfg = _config!;
    final now = DateTime.now();
    final date = '${now.day}/${now.month}/${now.year}';

    String termHeaderCols = cfg.termComponents
        .map((c) => '<th>${c.name}<br><small>(0–${c.maxMark.toStringAsFixed(0)})</small></th>')
        .join();
    String examHeaderCols = cfg.examComponents
        .map((c) => '<th>${c.name}<br><small>(0–${c.maxMark.toStringAsFixed(0)})</small></th>')
        .join();

    String termRows = _students.map((s) {
      final pct = _termPct(s.id);
      final hasData = cfg.termComponents.any((c) {
        final t = _termCtrls[s.id]?[c.id]?.text.trim() ?? '';
        return t.isNotEmpty && double.tryParse(t) != null;
      });
      final cells = cfg.termComponents.map((c) {
        final t = _termCtrls[s.id]?[c.id]?.text.trim() ?? '';
        return '<td>${t.isEmpty ? '—' : t}</td>';
      }).join();
      return '<tr><td>${s.name}</td>$cells'
          '<td>${hasData ? '${pct.toStringAsFixed(1)}%' : '—'}</td>'
          '<td>${hasData ? _grade(pct) : '—'}</td></tr>';
    }).join();

    final htmlPositions = _examPositions();
    String examRows = _students.map((s) {
      final pct = _examPct(s.id);
      final hasData = cfg.examComponents.any((c) {
        final t = _examCtrls[s.id]?[c.id]?.text.trim() ?? '';
        return t.isNotEmpty && double.tryParse(t) != null;
      });
      final cells = cfg.examComponents.map((c) {
        final t = _examCtrls[s.id]?[c.id]?.text.trim() ?? '';
        return '<td>${t.isEmpty ? '—' : t}</td>';
      }).join();
      final pos = htmlPositions[s.id];
      return '<tr><td>${s.name}</td>$cells'
          '<td>${hasData ? '${pct.toStringAsFixed(1)}%' : '—'}</td>'
          '<td>${hasData ? _grade(pct) : '—'}</td>'
          '<td>${pos != null ? _ordinal(pos) : '—'}</td></tr>';
    }).join();

    String summaryRows = _students.map((s) {
      final tPct = _termPct(s.id);
      final ePct = _examPct(s.id);
      final hasTerm = _hasTermData(s.id);
      final hasExam = _hasExamData(s.id);
      final hasAny = hasTerm || hasExam;
      final finalMark = tPct * 0.4 + ePct * 0.6;
      return '<tr><td>${s.name}</td>'
          '<td>${hasTerm ? '${tPct.toStringAsFixed(1)}%' : '—'}</td>'
          '<td>${hasExam ? '${ePct.toStringAsFixed(1)}%' : '—'}</td>'
          '<td>${hasAny ? finalMark.toStringAsFixed(1) : '—'}</td>'
          '<td>${hasAny ? _grade(finalMark) : '—'}</td></tr>';
    }).join();

    return '''<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<style>
  body { font-family: Arial, sans-serif; margin: 32px; color: #1a1a1a; }
  h1 { font-size: 20px; margin-bottom: 4px; }
  h2 { font-size: 15px; color: #555; margin-bottom: 16px; }
  h3 { font-size: 14px; margin: 24px 0 8px; }
  .meta { color: #666; font-size: 12px; margin-bottom: 24px; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 8px; }
  th, td { border: 1px solid #ccc; padding: 7px 10px; text-align: center; font-size: 13px; }
  th { background: #f5f5f5; font-weight: 700; }
  td:first-child { text-align: left; }
  .term th { background: #d1fae5; }
  .exam th { background: #ffedd5; }
  .summary th { background: #dbeafe; }
  @media print { body { margin: 16px; } }
</style>
</head><body>
<h1>$_className — $_subjectName</h1>
<h2>Marks Report</h2>
<p class="meta">Generated: $date &nbsp;|&nbsp; Students: ${_students.length}</p>

<h3>Term Marks (in-class tests)</h3>
<table class="term">
  <tr><th>Student</th>$termHeaderCols<th>Term %</th><th>Grade</th></tr>
  $termRows
</table>

<h3>Exam Marks (end-of-term examination)</h3>
<table class="exam">
  <tr><th>Student</th>$examHeaderCols<th>Exam %</th><th>Grade</th><th>Position</th></tr>
  $examRows
</table>

<h3>Summary (Final = Term% × 40% + Exam% × 60%)</h3>
<table class="summary">
  <tr><th>Student</th><th>Term %</th><th>Exam %</th><th>Final</th><th>Grade</th></tr>
  $summaryRows
</table>
</body></html>''';
  }

  void _downloadAsWord() {
    final content = _buildHtmlReport();
    final blob = html.Blob([content], 'application/msword');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download',
          'marks_${_className}_$_subjectName.doc'.replaceAll(' ', '_'))
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _openPrintPreview() {
    // Embed auto-print trigger so Ctrl+P / Save as PDF opens immediately
    final content = _buildHtmlReport().replaceFirst(
      '</body>',
      '<script>window.onload=function(){window.print();}</script></body>',
    );
    final blob = html.Blob([content], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Future.delayed(const Duration(seconds: 10),
        () => html.Url.revokeObjectUrl(url));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator()));
    }

    if (_students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: const Border.fromBorderSide(BorderSide(color: AppTheme.border)),
        ),
        child: const Center(
          child: Text('No students found in this class.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ),
      );
    }

    final state = AppStateProvider.read(context);
    final className =
        state.classes.firstWhere((c) => c.id == widget.classId).name;
    final subjectName =
        state.subjects.firstWhere((s) => s.id == widget.subjectId).name;
    final cfg = _config!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$className  —  $subjectName',
                      style: AppTheme.heading2),
                  const SizedBox(height: 2),
                  Text(
                      '${_students.length} students  •  '
                      'Final = Term% × 40% + Exam% × 60%',
                      style: AppTheme.caption),
                ],
              ),
            ),
            // ── Download dropdown ──────────────────────────────────────
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.picture_as_pdf_outlined,
                      size: 16),
                  onPressed: _openPrintPreview,
                  child: const Text('Save as PDF'),
                ),
                MenuItemButton(
                  leadingIcon:
                      const Icon(Icons.description_outlined, size: 16),
                  onPressed: _downloadAsWord,
                  child: const Text('Download as Word (.doc)'),
                ),
              ],
              builder: (_, ctrl, _) => OutlinedButton.icon(
                onPressed: ctrl.isOpen ? ctrl.close : ctrl.open,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Download'),
              ),
            ),
            const SizedBox(width: 10),
            // ── Save button ────────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _saveState == 1 ? null : _save,
              style: _saveState == 2
                  ? ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success)
                  : _saveState == 3
                      ? ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error)
                      : null,
              icon: _saveState == 1
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(
                      _saveState == 2
                          ? Icons.check_circle_outline
                          : _saveState == 3
                              ? Icons.error_outline
                              : Icons.save_outlined,
                      size: 16),
              label: Text(_saveState == 1
                  ? 'Saving…'
                  : _saveState == 2
                      ? 'Saved!'
                      : _saveState == 3
                          ? 'Error'
                          : 'Save Marks'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Term marks section ──────────────────────────────────────────────
        _SectionCard(
          title: 'Term Marks',
          subtitle: 'In-class tests',
          color: const Color(0xFFF0FDF4),
          borderColor: const Color(0xFFBBF7D0),
          headerColor: const Color(0xFF166534),
          components: cfg.termComponents,
          isTerm: true,
          students: _students,
          controllers: _termCtrls,
          focusNodes: _termFocus,
          nameCtrls: _nameCtrls,
          pctFn: _termPct,
          onAdd: () => _addComponent(true),
          onRemove: (id) => _removeComponent(id, true),
        ),
        const SizedBox(height: 20),

        // ── Exam marks section ──────────────────────────────────────────────
        _SectionCard(
          title: 'Exam Marks',
          subtitle: 'End-of-term examination',
          color: const Color(0xFFFFF7ED),
          borderColor: const Color(0xFFFED7AA),
          headerColor: const Color(0xFF9A3412),
          components: cfg.examComponents,
          isTerm: false,
          students: _students,
          controllers: _examCtrls,
          focusNodes: _examFocus,
          nameCtrls: _nameCtrls,
          pctFn: _examPct,
          positions: _examPositions(),
          onAdd: () => _addComponent(false),
          onRemove: (id) => _removeComponent(id, false),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // Competition ranking by exam% (students with no exam data are unranked).
  Map<String, int> _examPositions() {
    final ranked = _students
        .where((s) => _hasExamData(s.id))
        .map((s) => (id: s.id, pct: _examPct(s.id)))
        .toList()
      ..sort((a, b) => b.pct.compareTo(a.pct));

    final positions = <String, int>{};
    for (int i = 0; i < ranked.length; i++) {
      if (i > 0 && ranked[i].pct == ranked[i - 1].pct) {
        positions[ranked[i].id] = positions[ranked[i - 1].id]!;
      } else {
        positions[ranked[i].id] = i + 1;
      }
    }
    return positions;
  }

}

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Section card: term or exam
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Color borderColor;
  final Color headerColor;
  final List<MarkComponent> components;
  final bool isTerm;
  final List<Student> students;
  final Map<String, Map<String, TextEditingController>> controllers;
  final Map<String, Map<String, FocusNode>> focusNodes;
  final Map<String, TextEditingController> nameCtrls;
  final double Function(String studentId) pctFn;
  final Map<String, int>? positions;
  final VoidCallback onAdd;
  final void Function(String compId) onRemove;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.borderColor,
    required this.headerColor,
    required this.components,
    required this.isTerm,
    required this.students,
    required this.controllers,
    required this.focusNodes,
    required this.nameCtrls,
    required this.pctFn,
    this.positions,
    required this.onAdd,
    required this.onRemove,
  });

  static String _pctGrade(double pct) {
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B';
    if (pct >= 60) return 'C';
    if (pct >= 50) return 'D';
    return 'F';
  }

  // Column-major navigation: Down moves to next student in same column.
  // At the last student, wraps to the first student of the next column.
  FocusNode? _nextFocus(int studentIdx, int compIdx) {
    if (studentIdx < students.length - 1) {
      return focusNodes[students[studentIdx + 1].id]
          ?[components[compIdx].id];
    } else if (compIdx < components.length - 1) {
      return focusNodes[students[0].id]?[components[compIdx + 1].id];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.fromBorderSide(BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: headerColor)),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11, color: headerColor.withValues(alpha: 0.7))),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: Icon(Icons.add_circle_outline,
                      size: 16, color: headerColor),
                  label: Text('Add Component',
                      style: TextStyle(fontSize: 12, color: headerColor)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ),

          // Component chips
          if (components.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: components
                    .map((comp) => Chip(
                          label: Text(
                            '${comp.name}  (max ${comp.maxMark.toStringAsFixed(0)})',
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon:
                              const Icon(Icons.close, size: 14),
                          onDeleted: () => onRemove(comp.id),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ),

          if (components.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No components added. Click "Add Component" to add a test or exam.',
                style: TextStyle(
                    fontSize: 12, color: headerColor.withValues(alpha: 0.6)),
              ),
            )
          else
            // Table
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.fromBorderSide(
                    BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  // Header row
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                      border: Border(
                          bottom: BorderSide(color: borderColor)),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                            flex: 3, child: _ColHeader('STUDENT NAME')),
                        const SizedBox(width: 10),
                        ...components.map((comp) => Expanded(
                            child: _ColHeader(
                                '${comp.name.toUpperCase()}\n(0–${comp.maxMark.toStringAsFixed(0)})'))),
                        const SizedBox(width: 10),
                        SizedBox(
                            width: 64,
                            child: _ColHeader(
                                isTerm ? 'TERM %' : 'EXAM %')),
                        const SizedBox(width: 8),
                        const SizedBox(
                            width: 48,
                            child: _ColHeader('GRADE')),
                        if (positions != null) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                              width: 60,
                              child: _ColHeader('POSITION')),
                        ],
                      ],
                    ),
                  ),
                  // Student rows
                  ...students.asMap().entries.map((entry) {
                    final i = entry.key;
                    final student = entry.value;
                    final isLast = i == students.length - 1;
                    final pct = pctFn(student.id);
                    final hasData = components.any((c) {
                      final t =
                          controllers[student.id]?[c.id]?.text.trim() ??
                              '';
                      return t.isNotEmpty && double.tryParse(t) != null;
                    });
                    final sectionGrade = hasData ? _pctGrade(pct) : null;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: i.isEven
                            ? Colors.white
                            : const Color(0xFFFAFAFA),
                        borderRadius: isLast
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(6))
                            : null,
                        border: !isLast
                            ? Border(
                                bottom:
                                    BorderSide(color: borderColor))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: nameCtrls[student.id],
                              style:
                                  const TextStyle(fontSize: 13),
                              decoration:
                                  const InputDecoration(
                                isDense: true,
                                contentPadding:
                                    EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 7),
                                border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppTheme.border)),
                                enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppTheme.border)),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppTheme.primaryLight,
                                        width: 1.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ...components.asMap().entries.map((ce) {
                            final compIdx = ce.key;
                            final comp   = ce.value;
                            return Expanded(
                              child: _MarkField(
                                controller: controllers[student.id]?[comp.id],
                                focusNode:  focusNodes[student.id]?[comp.id],
                                nextFocusNode: _nextFocus(i, compIdx),
                                maxMark: comp.maxMark,
                              ),
                            );
                          }),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 64,
                            child: Text(
                              hasData
                                  ? '${pct.toStringAsFixed(1)}%'
                                  : '—',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasData
                                    ? headerColor
                                    : AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 48,
                            child: sectionGrade != null
                                ? GradeBadge(grade: sectionGrade)
                                : const Text('—',
                                    style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13)),
                          ),
                          if (positions != null) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: () {
                                final pos = positions![student.id];
                                if (pos == null) {
                                  return const Text('—',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13));
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: pos == 1
                                        ? const Color(0xFFFEF9C3)
                                        : pos == 2
                                            ? const Color(0xFFF1F5F9)
                                            : pos == 3
                                                ? const Color(0xFFFFF7ED)
                                                : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: pos == 1
                                          ? const Color(0xFFF59E0B)
                                          : AppTheme.border,
                                    ),
                                  ),
                                  child: Text(
                                    _ordinal(pos),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: pos == 1
                                          ? const Color(0xFF92400E)
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                );
                              }(),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _Dropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: const Border.fromBorderSide(
            BorderSide(color: AppTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.textSecondary,
        letterSpacing: 0.4,
        height: 1.4,
      ),
    );
  }
}

class _MarkField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final double maxMark;

  const _MarkField({
    this.controller,
    this.focusNode,
    this.nextFocusNode,
    required this.maxMark,
  });

  void _goNext() => nextFocusNode?.requestFocus();

  @override
  Widget build(BuildContext context) {
    final text = controller?.text.trim() ?? '';
    final val = double.tryParse(text);
    final isOver = val != null && val > maxMark;

    final errorBorder = OutlineInputBorder(
      borderSide: BorderSide(color: AppTheme.error, width: 1.5),
    );

    return Focus(
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _goNext();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onSubmitted: (_) => _goNext(),
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(r'^\d{0,4}(\.\d{0,1})?')),
        ],
        style: TextStyle(
            fontSize: 13,
            color: isOver ? AppTheme.error : null),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: '0',
          hintStyle: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 13),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: isOver
              ? errorBorder
              : const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.border)),
          enabledBorder: isOver
              ? errorBorder
              : const OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.border)),
          focusedBorder: isOver
              ? errorBorder
              : const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: AppTheme.primaryLight, width: 1.5)),
          errorText: isOver ? 'Max ${maxMark.toStringAsFixed(0)}' : null,
          errorStyle: const TextStyle(fontSize: 9, height: 0.8),
        ),
      ),
    );
  }
}


// ─── Add component dialog ─────────────────────────────────────────────────────

class _AddComponentDialog extends StatefulWidget {
  const _AddComponentDialog();

  @override
  State<_AddComponentDialog> createState() => _AddComponentDialogState();
}

class _AddComponentDialogState extends State<_AddComponentDialog> {
  final _nameCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  bool _hasError = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final max = double.tryParse(_maxCtrl.text.trim());
    if (name.isEmpty || max == null || max <= 0) {
      setState(() => _hasError = true);
      return;
    }
    Navigator.pop(context, (name: name, maxMark: max));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Component',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Name  (e.g. Test 1, Mid-Term)',
              errorText:
                  _hasError && _nameCtrl.text.trim().isEmpty
                      ? 'Required'
                      : null,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _maxCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Maximum marks  (e.g. 50)',
              errorText: _hasError &&
                      (double.tryParse(_maxCtrl.text.trim()) == null ||
                          double.tryParse(_maxCtrl.text.trim())! <= 0)
                  ? 'Enter a positive number'
                  : null,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}
