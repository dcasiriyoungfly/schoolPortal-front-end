import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/stat_card.dart';

class AdminClassesPage extends StatefulWidget {
  const AdminClassesPage({super.key});

  @override
  State<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<AdminClassesPage> {
  String? _expandedClassId;

  void _confirmPromoteAll(BuildContext context) {
    final state = AppStateProvider.read(context);
    final form4Classes = state.classes
        .where((c) => RegExp(r'^Form 4').hasMatch(c.name))
        .map((c) => c.name)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote All Classes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will advance every class by one year at the end of the academic year:',
            ),
            const SizedBox(height: 12),
            const Text('  Form 1  →  Form 2',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const Text('  Form 2  →  Form 3',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const Text('  Form 3A/B/C  →  Form 4A/B/C',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            if (form4Classes.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Form 4 classes will graduate and be permanently removed:',
                style: TextStyle(color: AppTheme.error, fontSize: 13),
              ),
              const SizedBox(height: 6),
              ...form4Classes.map((name) => Text(
                    '  • $name',
                    style: const TextStyle(
                        color: AppTheme.error, fontWeight: FontWeight.w600),
                  )),
            ],
            const SizedBox(height: 12),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary,
                  fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final graduated =
                  AppStateProvider.read(context).promoteClasses();
              Navigator.of(ctx).pop();
              setState(() => _expandedClassId = null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Classes promoted. $graduated student(s) graduated from Form 4.',
                  ),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('Promote All'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClass(BuildContext context, String classId, String className) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: Text(
          'Are you sure you want to delete "$className"? '
          'All students and marks in this class will also be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await AppStateProvider.read(context).deleteClass(classId);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                setState(() => _expandedClassId = null);
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete class: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddClassDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Class'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Class Name',
            hintText: 'e.g. Form 5A',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await AppStateProvider.read(context).addClass(name);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add class: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add Class'),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, String classId, String className) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Student to $className'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Student Name',
            hintText: 'e.g. John Banda',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await AppStateProvider.read(context).addStudent(name, classId);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add student: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Classes', style: AppTheme.heading1),
                    SizedBox(height: 4),
                    Text(
                      'Overview of all classes, assigned teachers and students.',
                      style: AppTheme.label,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmPromoteAll(context),
                icon: const Icon(Icons.upgrade_rounded, size: 16),
                label: const Text('Promote All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddClassDialog(context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Class'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Summary row ──────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total Classes',
                  value: '${state.classes.length}',
                  accentColor: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Total Students',
                  value: '${state.students.length}',
                  subtitle: state.classes.isNotEmpty
                      ? 'Avg ${(state.students.length / state.classes.length).toStringAsFixed(0)} per class'
                      : '',
                  accentColor: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  label: 'Total Subjects',
                  value: '${state.subjects.length}',
                  subtitle: state.classes.isNotEmpty
                      ? '${(state.subjects.length / state.classes.length).toStringAsFixed(0)} avg per class'
                      : '',
                  accentColor: const Color(0xFF0891B2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Class cards ───────────────────────────────────────────────────
          const SectionHeader(
            title: 'Class Details',
            subtitle: 'Select a class to view its student roster.',
          ),
          const SizedBox(height: 14),
          ...state.classes.map((cls) {
            final students = state.getStudentsInClass(cls.id);
            final teachers = state.teachers
                .where((t) => cls.teacherIds.contains(t.id))
                .toList();
            final subjects = state.subjects
                .where((s) => cls.teacherIds.contains(s.teacherId))
                .toList();
            final isExpanded = _expandedClassId == cls.id;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.fromBorderSide(BorderSide(
                  color: isExpanded
                      ? AppTheme.primaryLight
                      : AppTheme.border,
                  width: isExpanded ? 1.5 : 1,
                )),
              ),
              child: Column(
                children: [
                  // Class header row
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() {
                      _expandedClassId = isExpanded ? null : cls.id;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cls.name.split(' ').last,
                              style: const TextStyle(
                                color: AppTheme.primaryLight,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cls.name,
                                    style: AppTheme.heading3),
                                const SizedBox(height: 2),
                                Text(
                                  '${students.length} students  •  '
                                  '${teachers.length} teachers  •  '
                                  '${subjects.length} subjects',
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.error, size: 20),
                            tooltip: 'Delete Class',
                            onPressed: () => _confirmDeleteClass(context, cls.id, cls.name),
                          ),
                          // Teachers chips
                          ...teachers.map(
                            (t) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                t.name.split(' ').skip(1).join(' '),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expanded: student roster
                  if (isExpanded) ...[
                    const Divider(height: 1, color: AppTheme.border),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Student Roster',
                                  style: AppTheme.heading3,
                                ),
                              ),
                              Text(
                                'Subjects: ${subjects.map((s) => s.name).join(', ')}',
                                style: AppTheme.caption,
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _showAddStudentDialog(context, cls.id, cls.name),
                                icon: const Icon(Icons.person_add_outlined, size: 16),
                                label: const Text('Add Student'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppTable(
                            headers: const ['#', 'STUDENT NAME', 'CLASS'],
                            columnWidths: const [48, null, 120],
                            rows: students.asMap().entries.map((e) {
                              return [
                                Text('${e.key + 1}',
                                    style: AppTheme.caption),
                                Text(e.value.name, style: AppTheme.body),
                                Text(cls.name,
                                    style: AppTheme.caption),
                              ];
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
