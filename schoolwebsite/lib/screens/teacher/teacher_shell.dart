import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/app_sidebar.dart';
import 'package:schoolwebsite/screens/teacher/teacher_dashboard_page.dart';
import 'package:schoolwebsite/screens/teacher/teacher_marks_entry_page.dart';
import 'package:schoolwebsite/screens/teacher/teacher_change_password_page.dart';
import 'package:schoolwebsite/screens/teacher/teacher_students_page.dart';

const _teacherNavItems = [
  SidebarNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
  SidebarNavItem(label: 'Marks Entry', icon: Icons.edit_note_rounded),
  SidebarNavItem(label: 'Students', icon: Icons.people_outline_rounded),
  SidebarNavItem(label: 'Change Password', icon: Icons.lock_outline_rounded),
];

class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    final pages = [
      const TeacherDashboardPage(),
      const TeacherMarksEntryPage(),
      const TeacherStudentsPage(),
      const TeacherChangePasswordPage(),
    ];

    final sidebar = AppSidebar(
      schoolName: 'Excellence High School',
      userName: state.currentUser?.name ?? '',
      userRoleLabel: 'Teacher',
      items: _teacherNavItems,
      selectedIndex: state.teacherPageIndex,
      onSelected: (i) {
        state.setTeacherPage(i);
        if (isMobile) Navigator.of(context).pop();
      },
      onLogout: state.logout,
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.sidebarBg,
          foregroundColor: AppTheme.sidebarTextActive,
          elevation: 0,
          title: Text(
            _teacherNavItems[state.teacherPageIndex].label,
            style: const TextStyle(
              color: AppTheme.sidebarTextActive,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        drawer: Drawer(
          width: 260,
          backgroundColor: AppTheme.sidebarBg,
          child: SafeArea(child: sidebar),
        ),
        body: pages[state.teacherPageIndex],
      );
    }

    return Scaffold(
      body: Row(
        children: [
          sidebar,
          Expanded(child: pages[state.teacherPageIndex]),
        ],
      ),
    );
  }
}
