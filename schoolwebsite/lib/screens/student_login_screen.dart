import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
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

  Future<void> _login() async {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();

    if (userId.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Student ID.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }

    final state = AppStateProvider.read(context);
    final success = await state.loginAsRoleAsync(userId, password, 'student');
    if (!mounted) return;
    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() => _errorMessage = 'Incorrect Student ID or password.');
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
        const Text('Student Sign In', style: AppTheme.heading1),
        const SizedBox(height: 6),
        const Text(
          'Enter your Student ID and password to access your results.',
          style: AppTheme.label,
        ),
        const SizedBox(height: 32),
        const Text('Student ID', style: AppTheme.heading3),
        const SizedBox(height: 8),
        TextField(
          controller: _userIdController,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Enter your Student ID',
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
            decoration: BoxDecoration(
              color: AppTheme.errorBg, borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0891B2), foregroundColor: Colors.white,
            ),
            child: const Text('Sign In'),
          ),
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
                  color: const Color(0xFF0C4A6E),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Row(
                    children: [
                      Container(
                        width: 4, height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Excellence High School',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('Student Portal',
                            style: TextStyle(color: Color(0xFF7DD3FC), fontSize: 12)),
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
              color: const Color(0xFF0C4A6E),
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8), borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Excellence\nHigh School',
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 16),
                  const Text('Student Portal',
                    style: TextStyle(color: Color(0xFF7DD3FC), fontSize: 15)),
                  const SizedBox(height: 48),
                  const _InfoItem(icon: Icons.bar_chart_rounded, text: 'View your term results and grades.'),
                  const SizedBox(height: 16),
                  const _InfoItem(icon: Icons.description_rounded, text: 'Download and print your report card.'),
                  const SizedBox(height: 16),
                  const _InfoItem(icon: Icons.trending_up_rounded, text: 'Track your academic performance.'),
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
        Icon(icon, color: const Color(0xFF7DD3FC), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFBAE6FD),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
