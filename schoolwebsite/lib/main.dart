import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/state/app_state.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/screens/landing_screen.dart';
import 'package:schoolwebsite/screens/admin/admin_shell.dart';
import 'package:schoolwebsite/screens/teacher/teacher_shell.dart';
import 'package:schoolwebsite/screens/student/student_shell.dart';

void main() {
  runApp(const SchoolPortalApp());
}

class SchoolPortalApp extends StatefulWidget {
  const SchoolPortalApp({super.key});

  @override
  State<SchoolPortalApp> createState() => _SchoolPortalAppState();
}

class _SchoolPortalAppState extends State<SchoolPortalApp> {
  final AppState _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      notifier: _appState,
      child: MaterialApp(
        title: 'Excellence High School — Results Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AppRoot(),
      ),
    );
  }
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);

    if (state.currentUser == null) {
      return const LandingScreen();
    }

    switch (state.currentUser!.role) {
      case UserRole.admin:
        return const AdminShell();
      case UserRole.teacher:
        return const TeacherShell();
      case UserRole.student:
        return const StudentShell();
    }
  }
}
