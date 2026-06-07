import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';

class TeacherStudentsPage extends StatelessWidget {
  const TeacherStudentsPage({super.key});

  void _showAddStudentDialog(
      BuildContext context, String classId, String className) {
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
          onSubmitted: (value) async {
            final name = value.trim();
            if (name.isEmpty) return;
            await AppStateProvider.read(context).addStudent(name, classId);
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop();
          },
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
              await AppStateProvider.read(context).addStudent(name, classId);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
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
    final teacherId = state.currentUser?.linkedId ?? '';

    final teacher = state.teachers.firstWhere(
      (t) => t.id == teacherId,
      orElse: () =>
          const Teacher(id: '', name: '', subjectIds: [], classIds: []),
    );

    final myClasses = state.classes
        .where((c) => teacher.classIds.contains(c.id))
        .toList();

    final isMobile = MediaQuery.of(context).size.width < 600;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          const Text('My Students', style: AppTheme.heading1),
          const SizedBox(height: 4),
          const Text(
            'View and add students to your assigned classes.',
            style: AppTheme.label,
          ),
          const SizedBox(height: 32),

          if (myClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border:
                    const Border.fromBorderSide(BorderSide(color: AppTheme.border)),
              ),
              child: const Center(
                child: Text(
                  'You have no assigned classes yet.',
                  style: AppTheme.label,
                ),
              ),
            )
          else
            ...myClasses.map((cls) {
              final students = state.students
                  .where((s) => s.classId == cls.id)
                  .toList();
              return _ClassStudentCard(
                cls: cls,
                students: students,
                onAddStudent: () =>
                    _showAddStudentDialog(context, cls.id, cls.name),
              );
            }),
        ],
      ),
    );
  }
}

class _ClassStudentCard extends StatelessWidget {
  final ClassGroup cls;
  final List<Student> students;
  final VoidCallback onAddStudent;

  const _ClassStudentCard({
    required this.cls,
    required this.students,
    required this.onAddStudent,
  });

  void _confirmDelete(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student'),
        content: Text(
            'Remove ${student.name} from this class? This will also delete their marks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppStateProvider.read(context).deleteStudent(student.id);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: const Border.fromBorderSide(BorderSide(color: AppTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded,
                    size: 18, color: AppTheme.primaryLight),
                const SizedBox(width: 10),
                Text(cls.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${students.length} student${students.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onAddStudent,
                  icon: const Icon(Icons.person_add_outlined, size: 15),
                  label: const Text('Add Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // ── Student list ────────────────────────────────────────────────
          if (students.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No students in this class yet. Press "Add Student" to add one.',
                style: AppTheme.label,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: students.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (context, index) {
                final student = students[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppTheme.primaryLight.withValues(alpha: 0.12),
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(student.name,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      Text(
                        student.id,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppTheme.error),
                        tooltip: 'Remove student',
                        onPressed: () => _confirmDelete(
                            context, student),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
