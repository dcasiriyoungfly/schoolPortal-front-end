import 'package:flutter/material.dart';
import 'package:schoolwebsite/app_theme.dart';
import 'package:schoolwebsite/state/app_state_provider.dart';

class TeacherChangePasswordPage extends StatefulWidget {
  const TeacherChangePasswordPage({super.key});

  @override
  State<TeacherChangePasswordPage> createState() =>
      _TeacherChangePasswordPageState();
}

class _TeacherChangePasswordPageState
    extends State<TeacherChangePasswordPage> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  bool _success = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final state = AppStateProvider.read(context);
    final userId = state.currentUser?.id ?? '';
    final current = _currentCtrl.text;
    final newPw = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    setState(() {
      _errorMessage = null;
      _success = false;
    });

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'All fields are required.');
      return;
    }
    if (newPw.length < 6) {
      setState(
          () => _errorMessage = 'New password must be at least 6 characters.');
      return;
    }
    if (newPw != confirm) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }
    if (newPw == current) {
      setState(() =>
          _errorMessage = 'New password must differ from the current one.');
      return;
    }

    final ok = state.changePassword(userId, current, newPw);
    if (!ok) {
      setState(() => _errorMessage = 'Current password is incorrect.');
      return;
    }

    // Clear fields and show success
    _currentCtrl.clear();
    _newCtrl.clear();
    _confirmCtrl.clear();
    setState(() => _success = true);
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
          const Text('Change Password', style: AppTheme.heading1),
          const SizedBox(height: 4),
          const Text(
            'Update your account password. '
            'You will need to use the new password on your next login.',
            style: AppTheme.label,
          ),
          const SizedBox(height: 32),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: const Border.fromBorderSide(
                    BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Account info banner ─────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: const Border.fromBorderSide(
                          BorderSide(color: Color(0xFFBFDBFE))),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 16, color: AppTheme.primaryLight),
                        const SizedBox(width: 8),
                        Text(
                          'Logged in as: ${state.currentUser?.name ?? ''}  '
                          '(ID: ${state.currentUser?.id ?? ''})',
                          style: const TextStyle(
                            color: AppTheme.primaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Success banner ──────────────────────────────────────
                  if (_success) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.successBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle_outline,
                              size: 18, color: AppTheme.success),
                          SizedBox(width: 8),
                          Text(
                            'Password changed successfully.',
                            style: TextStyle(
                                color: AppTheme.success,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Current password ────────────────────────────────────
                  const Text('Current Password', style: AppTheme.heading3),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _currentCtrl,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      hintText: 'Enter your current password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                            size: 18),
                        onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    onChanged: (_) =>
                        setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 20),

                  // ── New password ────────────────────────────────────────
                  const Text('New Password', style: AppTheme.heading3),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _newCtrl,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      hintText: 'Minimum 6 characters',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                            size: 18),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    onChanged: (_) =>
                        setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 20),

                  // ── Confirm new password ────────────────────────────────
                  const Text('Confirm New Password',
                      style: AppTheme.heading3),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmCtrl,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      hintText: 'Re-enter new password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                            size: 18),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) =>
                        setState(() => _errorMessage = null),
                  ),

                  // ── Error ───────────────────────────────────────────────
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Submit ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Update Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
