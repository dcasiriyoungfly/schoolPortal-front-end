import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/models/models.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';

class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  // Staff can be admin or teacher
  UserRole _selectedRole = UserRole.admin;
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      _userIdController.clear();
      _errorMessage = null;
      _passwordController.clear();
    });
  }

  Future<void> _login() async {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (userId.isEmpty) {
      setState(() => _errorMessage = 'Please enter your User ID.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    final state = AppStateProvider.read(context);
    try {
      final success = await state.loginAsRoleAsync(userId, password, _selectedRole.name);
      if (!mounted) return;
      if (success) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    }
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Staff Sign In', style: AppTheme.heading1),
        const SizedBox(height: 6),
        const Text('Select your role and enter your credentials.', style: AppTheme.label),
        const SizedBox(height: 32),
        const Text('Role', style: AppTheme.heading3),
        const SizedBox(height: 8),
        Row(
          children: [UserRole.admin, UserRole.teacher].map((role) {
            final isSelected = role == _selectedRole;
            final label = role == UserRole.admin ? 'Administrator' : 'Teacher';
            return Expanded(
              child: GestureDetector(
                onTap: () => _onRoleChanged(role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: EdgeInsets.only(right: role == UserRole.admin ? 10 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.fromBorderSide(BorderSide(
                      color: isSelected ? AppTheme.primary : AppTheme.border,
                      width: isSelected ? 1.5 : 1,
                    )),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        const Text('User ID', style: AppTheme.heading3),
        const SizedBox(height: 8),
        TextField(
          controller: _userIdController,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Enter your User ID',
            prefixIcon: Icon(Icons.badge_outlined, size: 18),
          ),
          onChanged: (_) => setState(() => _errorMessage = null),
          onSubmitted: (_) => _login(),
        ),
        const SizedBox(height: 20),
        const Text('Password', style: AppTheme.heading3),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: AppTheme.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          onSubmitted: (_) => _login(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.errorBg, borderRadius: BorderRadius.circular(6)),
            child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 44,
          child: ElevatedButton(onPressed: _login, child: const Text('Sign In')),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: AppTheme.sidebarBg,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Row(
                    children: [
                      Container(
                        width: 4, height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.sidebarAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Excellence High School',
                            style: TextStyle(color: AppTheme.sidebarTextActive, fontSize: 16, fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('Staff Portal',
                            style: TextStyle(color: AppTheme.sidebarText, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildForm(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: AppTheme.sidebarBg,
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4, height: 48,
                    decoration: BoxDecoration(color: AppTheme.sidebarAccent, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 24),
                  const Text('Excellence\nHigh School',
                    style: TextStyle(color: AppTheme.sidebarTextActive, fontSize: 32, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 16),
                  const Text('Staff Portal', style: TextStyle(color: AppTheme.sidebarText, fontSize: 15)),
                  const SizedBox(height: 48),
                  const _InfoItem(icon: Icons.admin_panel_settings_rounded, text: 'Administrators manage classes, teachers and reports.'),
                  const SizedBox(height: 16),
                  const _InfoItem(icon: Icons.edit_note_rounded, text: 'Teachers enter and submit student marks.'),
                  const SizedBox(height: 16),
                  const _InfoItem(icon: Icons.bar_chart_rounded, text: 'View analytics and generate term reports.'),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.sidebarAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.sidebarText,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
