import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';
import 'package:schoolwebsite/widgets/app_sidebar.dart';
import 'package:schoolwebsite/screens/admin/admin_dashboard_page.dart';
import 'package:schoolwebsite/screens/admin/admin_analytics_page.dart';
import 'package:schoolwebsite/screens/admin/admin_classes_page.dart';
import 'package:schoolwebsite/screens/admin/admin_teachers_page.dart';
import 'package:schoolwebsite/screens/admin/admin_report_page.dart';
import 'package:schoolwebsite/screens/admin/admin_applications_page.dart';
import 'package:schoolwebsite/screens/teacher/teacher_change_password_page.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  static const _pages = [
    AdminDashboardPage(),
    AdminAnalyticsPage(),
    AdminClassesPage(),
    AdminTeachersPage(),
    AdminReportPage(),
    AdminApplicationsPage(),
    TeacherChangePasswordPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppStateProvider.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final pendingApps = state.pendingApplicationsCount;

    final navItems = [
      const SidebarNavItem(label: 'Dashboard', icon: Icons.grid_view_rounded),
      const SidebarNavItem(label: 'Analytics', icon: Icons.bar_chart_rounded),
      const SidebarNavItem(label: 'Classes', icon: Icons.groups_rounded),
      const SidebarNavItem(label: 'Teachers', icon: Icons.person_rounded),
      const SidebarNavItem(label: 'Reports', icon: Icons.description_rounded),
      SidebarNavItem(
        label: 'Applications',
        icon: Icons.inbox_rounded,
        badgeCount: pendingApps,
      ),
      const SidebarNavItem(label: 'Change Password', icon: Icons.lock_outline_rounded),
    ];

    final sidebar = AppSidebar(
      schoolName: 'Excellence High School',
      userName: state.currentUser?.name ?? '',
      userRoleLabel: 'Administrator',
      items: navItems,
      selectedIndex: state.adminPageIndex,
      onSelected: (i) {
        state.setAdminPage(i);
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
            navItems[state.adminPageIndex].label,
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
        body: _pages[state.adminPageIndex],
      );
    }

    return Scaffold(
      body: Row(
        children: [
          sidebar,
          Expanded(child: _pages[state.adminPageIndex]),
        ],
      ),
    );
  }
}
