import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/screens/staff_login_screen.dart';
import 'package:schoolwebsite/screens/student_login_screen.dart';

/// Landing page — user chooses Student Portal or Staff Portal.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sidebarBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return isMobile ? _MobileLayout() : _DesktopLayout();
        },
      ),
    );
  }
}

// ── Desktop layout (original side-by-side) ────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4, height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.sidebarAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Excellence\nHigh School',
                  style: TextStyle(
                    color: AppTheme.sidebarTextActive,
                    fontSize: 36, fontWeight: FontWeight.w800, height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Results Management Portal',
                  style: TextStyle(color: AppTheme.sidebarText, fontSize: 15),
                ),
                const SizedBox(height: 56),
                const Text(
                  'Academic Year 2025/2026',
                  style: TextStyle(color: AppTheme.sidebarText, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Term 1',
                  style: TextStyle(
                    color: AppTheme.sidebarAccent, fontSize: 13, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(
            color: AppTheme.background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: _PortalContent(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Mobile layout (stacked) ───────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Compact branding header
              Container(
                width: double.infinity,
                color: AppTheme.sidebarBg,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Row(
                  children: [
                    Container(
                      width: 4, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.sidebarAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Excellence High School',
                          style: TextStyle(
                            color: AppTheme.sidebarTextActive,
                            fontSize: 18, fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Results Management Portal',
                          style: TextStyle(color: AppTheme.sidebarText, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Portal selection
              Padding(
                padding: const EdgeInsets.all(24),
                child: _PortalContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared portal selection content ───────────────────────────────────────────

class _PortalContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Welcome', style: AppTheme.heading1),
        const SizedBox(height: 6),
        const Text('Select your portal to continue.', style: AppTheme.label),
        const SizedBox(height: 32),
        if (isMobile)
          Column(
            children: [
              _PortalCard(
                icon: Icons.school_rounded,
                title: 'Student Portal',
                description: 'View your results, report card and performance.',
                color: const Color(0xFF0891B2),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _PortalCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Staff Portal',
                description: 'Administrator and teacher access to manage marks.',
                color: AppTheme.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _PortalCard(
                  icon: Icons.school_rounded,
                  title: 'Student Portal',
                  description: 'View your results,\nreport card and performance.',
                  color: const Color(0xFF0891B2),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StudentLoginScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _PortalCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Staff Portal',
                  description: 'Administrator and teacher\naccess to manage marks.',
                  color: AppTheme.primary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PortalCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _PortalCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  State<_PortalCard> createState() => _PortalCardState();
}

class _PortalCardState extends State<_PortalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _hovered ? widget.color : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.fromBorderSide(BorderSide(
              color: _hovered ? widget.color : AppTheme.border,
              width: _hovered ? 1.5 : 1,
            )),
            boxShadow: _hovered
                ? [BoxShadow(color: widget.color.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _hovered ? Colors.white.withValues(alpha: 0.2) : widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: _hovered ? Colors.white : widget.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: _hovered ? Colors.white : AppTheme.textPrimary,
                        fontSize: 15, fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: _hovered ? Colors.white.withValues(alpha: 0.85) : AppTheme.textSecondary,
                        fontSize: 12, height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: _hovered ? Colors.white : widget.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
