import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';

class AdminTeachersPage extends StatelessWidget {
  const AdminTeachersPage({super.key});

  void _showAddTeacherDialog(BuildContext context) {
    final state = AppStateProvider.read(context);
    final nameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final subjectControllers = <TextEditingController>[TextEditingController()];
    final selectedClassIds = <String>{};
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Teacher'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Auto-ID notice ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: const Border.fromBorderSide(
                          BorderSide(color: Color(0xFFBFDBFE))),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppTheme.primaryLight),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'A unique User ID (S001, S002…) will be assigned automatically.',
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.primaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Personal info ────────────────────────────────────────
                  const Text('Teacher Details', style: AppTheme.heading3),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g. Mr. John Phiri',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Subjects ─────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                          child: Text('Subjects to Teach',
                              style: AppTheme.heading3)),
                      TextButton.icon(
                        onPressed: () => setDialogState(() {
                          subjectControllers.add(TextEditingController());
                        }),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Subject'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...subjectControllers.asMap().entries.map((entry) {
                    final i = entry.key;
                    final ctrl = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Subject ${i + 1}',
                                hintText: 'e.g. Physics',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          if (subjectControllers.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppTheme.error),
                              onPressed: () => setDialogState(() {
                                subjectControllers.removeAt(i);
                              }),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // ── Classes ──────────────────────────────────────────────
                  const Text('Assign to Classes', style: AppTheme.heading3),
                  const SizedBox(height: 8),
                  ...state.classes.map((cls) {
                    return CheckboxListTile(
                      value: selectedClassIds.contains(cls.id),
                      title: Text(cls.name),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (v) => setDialogState(() {
                        if (v == true) {
                          selectedClassIds.add(cls.id);
                        } else {
                          selectedClassIds.remove(cls.id);
                        }
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final password = passwordCtrl.text.trim();
                final subjectNames = subjectControllers
                    .map((c) => c.text.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                if (name.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Name and Password are required.')),
                  );
                  return;
                }

                String assignedId;
                try {
                  assignedId = await AppStateProvider.read(context).addTeacher(
                    name: name,
                    password: password,
                    subjectNames: subjectNames,
                    classIds: selectedClassIds.toList(),
                  );
                } catch (e) {
                  if (!ctx.mounted) return;
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add teacher: $e'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();

                // Show the assigned ID so the admin can note it down
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Teacher Added'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$name has been added successfully.'),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                            border: const Border.fromBorderSide(
                                BorderSide(color: Color(0xFFBFDBFE))),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Assigned User ID',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                assignedId,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                    letterSpacing: 2),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Share this ID with the teacher so they can log in.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Add Teacher'),
            ),
          ],
        ),
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
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teachers', style: AppTheme.heading1),
                    SizedBox(height: 4),
                    Text(
                      'Add teachers, then assign their classes and subjects.',
                      style: AppTheme.label,
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddTeacherDialog(context),
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Add Teacher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          ...state.teachers.map((teacher) {
            return _TeacherAssignmentCard(
              key: ValueKey(teacher.id),
              teacher: teacher,
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TeacherAssignmentCard extends StatefulWidget {
  final Teacher teacher;
  const _TeacherAssignmentCard({super.key, required this.teacher});

  @override
  State<_TeacherAssignmentCard> createState() => _TeacherAssignmentCardState();
}

class _TeacherAssignmentCardState extends State<_TeacherAssignmentCard> {
  bool _expanded = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text(
          'Are you sure you want to remove ${widget.teacher.name}? '
          'This will also delete their subjects and all related marks.',
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
                await AppStateProvider.read(ctx)
                    .deleteTeacher(widget.teacher.id);
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
              } catch (e) {
                if (!ctx.mounted) return;
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete teacher: $e'),
                    backgroundColor: AppTheme.error,
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

  void _showClassDialog() {
    final state = AppStateProvider.read(context);
    final selected = Set<String>.from(widget.teacher.classIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Assign Classes — ${widget.teacher.name}'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: state.classes.map((cls) {
                final checked = selected.contains(cls.id);
                return CheckboxListTile(
                  value: checked,
                  title: Text(cls.name),
                  onChanged: (v) => setDialogState(() {
                    if (v == true) {
                      selected.add(cls.id);
                    } else {
                      selected.remove(cls.id);
                    }
                  }),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await state.setTeacherClasses(widget.teacher.id, selected.toList());
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                } catch (e) {
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppTheme.error),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectDialog() {
    final state = AppStateProvider.read(context);
    final selected = Set<String>.from(widget.teacher.subjectIds);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Assign Subjects — ${widget.teacher.name}'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: state.subjects.map((sub) {
                final checked = selected.contains(sub.id);
                return CheckboxListTile(
                  value: checked,
                  title: Text(sub.name),
                  onChanged: (v) => setDialogState(() {
                    if (v == true) {
                      selected.add(sub.id);
                    } else {
                      selected.remove(sub.id);
                    }
                  }),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await state.setTeacherSubjects(widget.teacher.id, selected.toList());
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                } catch (e) {
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppTheme.error),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final teacher = widget.teacher;
    final assignedClasses =
        state.classes.where((c) => teacher.classIds.contains(c.id)).toList();
    final assignedSubjects =
        state.subjects.where((s) => teacher.subjectIds.contains(s.id)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.fromBorderSide(BorderSide(
          color: _expanded ? AppTheme.primaryLight : AppTheme.border,
          width: _expanded ? 1.5 : 1,
        )),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      teacher.name.split(' ').last[0],
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teacher.name, style: AppTheme.heading3),
                        const SizedBox(height: 2),
                        Text(
                          '${assignedClasses.length} class(es)  •  '
                          '${assignedSubjects.length} subject(s)',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error, size: 20),
                    tooltip: 'Delete Teacher',
                    onPressed: () => _confirmDelete(context),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppTheme.border),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Assigned Classes',
                                  style: AppTheme.heading3),
                            ),
                            TextButton.icon(
                              onPressed: _showClassDialog,
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (assignedClasses.isEmpty)
                          const Text('No classes assigned.',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: assignedClasses
                                .map((c) => _Chip(label: c.name))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Assigned Subjects',
                                  style: AppTheme.heading3),
                            ),
                            TextButton.icon(
                              onPressed: _showSubjectDialog,
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (assignedSubjects.isEmpty)
                          const Text('No subjects assigned.',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13))
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: assignedSubjects
                                .map((s) => _Chip(label: s.name))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
        border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFBFDBFE))),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
