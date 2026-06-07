import 'package:flutter/material.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/app_sidebar.dart';
import 'package:schoolwebsite/screens/student/student_dashboard_page.dart';
import 'package:schoolwebsite/screens/student/student_report_card_page.dart';

const _navItems = [
  SidebarNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
  SidebarNavItem(label: 'Report Card', icon: Icons.article_rounded),
];

class StudentShell extends StatelessWidget {
  const StudentShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final pages = [
      const StudentDashboardPage(),
      const StudentReportCardPage(),
    ];

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            schoolName: 'Excellence High School',
            userName: state.currentUser?.name ?? '',
            userRoleLabel: 'Student',
            items: _navItems,
            selectedIndex: state.studentPageIndex,
            onSelected: state.setStudentPage,
            onLogout: state.logout,
          ),
          Expanded(child: pages[state.studentPageIndex]),
        ],
      ),
    );
  }
}
