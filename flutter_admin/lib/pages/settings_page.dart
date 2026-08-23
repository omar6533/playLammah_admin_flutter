import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

@RoutePage()
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();

  // ── Add portal user ──────────────────────────────────────────────────────

  Future<void> _showAddUserDialog() async {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    bool showPass = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.person_add_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text('Add Portal User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    controller: emailCtrl,
                    label: 'Email address',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    controller: passCtrl,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscure: !showPass,
                    suffix: IconButton(
                      icon: Icon(showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                      onPressed: () => setDialogState(() => showPass = !showPass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    controller: confirmCtrl,
                    label: 'Confirm password',
                    icon: Icons.lock_outline_rounded,
                    obscure: !showPass,
                    validator: (v) {
                      if (v != passCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => loading = true);
                      try {
                        await _authService.createAdminUser(
                          emailCtrl.text.trim(),
                          passCtrl.text,
                        );
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _showSnackbar('User ${emailCtrl.text.trim()} created successfully.', success: true);
                      } catch (e) {
                        setDialogState(() => loading = false);
                        _showSnackbar(_friendlyError(e.toString()), success: false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Change own password ──────────────────────────────────────────────────

  Future<void> _showChangePasswordDialog() async {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    bool showPass = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.key_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 10),
              Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogField(
                    controller: passCtrl,
                    label: 'New password',
                    icon: Icons.lock_outline_rounded,
                    obscure: !showPass,
                    suffix: IconButton(
                      icon: Icon(showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                      onPressed: () => setDialogState(() => showPass = !showPass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Minimum 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _dialogField(
                    controller: confirmCtrl,
                    label: 'Confirm new password',
                    icon: Icons.lock_outline_rounded,
                    obscure: !showPass,
                    validator: (v) {
                      if (v != passCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: loading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => loading = true);
                      try {
                        await _authService.changeOwnPassword(passCtrl.text);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        _showSnackbar('Password updated successfully.', success: true);
                      } catch (e) {
                        setDialogState(() => loading = false);
                        final msg = e.toString().contains('requires-recent-login')
                            ? 'Session expired. Please sign out and sign in again, then retry.'
                            : _friendlyError(e.toString());
                        _showSnackbar(msg, success: false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Send reset email ─────────────────────────────────────────────────────

  Future<void> _sendReset(String email) async {
    try {
      await _authService.resetPassword(email);
      _showSnackbar('Password reset email sent to $email.', success: true);
    } catch (e) {
      _showSnackbar(_friendlyError(e.toString()), success: false);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  void _showSnackbar(String msg, {required bool success}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: success ? AppColors.success : AppColors.danger,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) return 'This email already has a portal account.';
    if (raw.contains('invalid-email')) return 'Invalid email address.';
    if (raw.contains('weak-password')) return 'Password is too weak.';
    if (raw.contains('network-request-failed')) return 'Network error. Check your connection.';
    if (raw.contains('requires-recent-login')) return 'Session expired. Sign out and sign in again.';
    return raw.replaceAll('Exception: ', '').replaceAll('[firebase_auth/', '').replaceAll(']', '');
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final me = _authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 28),

            // ── My Account ─────────────────────────────────────────────────
            _SectionCard(
              title: 'My Account',
              icon: Icons.manage_accounts_rounded,
              action: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.key_rounded, size: 16),
                label: const Text('Change Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.email_outlined, label: 'Email', value: me?.email ?? '—'),
                  const Divider(height: 1),
                  _InfoRow(icon: Icons.fingerprint_rounded, label: 'User ID', value: me?.uid ?? '—', mono: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Portal Users ────────────────────────────────────────────────
            _SectionCard(
              title: 'Portal Users',
              icon: Icons.group_rounded,
              action: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.person_add_rounded, size: 16),
                label: const Text('Add User', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _authService.getAdminUsers(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error loading users: ${snap.error}',
                          style: const TextStyle(color: AppColors.danger)),
                    );
                  }
                  final users = snap.data ?? [];
                  if (users.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                          SizedBox(width: 10),
                          Text(
                            'No portal users yet. Click "Add User" to invite someone.',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: users.asMap().entries.map((entry) {
                      final i = entry.key;
                      final u = entry.value;
                      final email = u['email'] as String? ?? '—';
                      final isMe = email == me?.email;
                      return Column(
                        children: [
                          if (i > 0) const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primaryLight
                                        : AppColors.background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: isMe ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            email,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (isMe) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryLight,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'You',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (u['createdBy'] != null && (u['createdBy'] as String).isNotEmpty)
                                        Text(
                                          'Added by ${u['createdBy']}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isMe)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: _showChangePasswordDialog,
                                    icon: const Icon(Icons.key_rounded, size: 15),
                                    label: const Text('Change Password', style: TextStyle(fontSize: 12)),
                                  )
                                else
                                  Tooltip(
                                    message: 'Sends a password-reset link to this user\'s inbox',
                                    child: TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.textSecondary,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onPressed: () => _sendReset(email),
                                      icon: const Icon(Icons.email_outlined, size: 15),
                                      label: const Text('Send Reset Email', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared dialog field helper ─────────────────────────────────────────────

Widget _dialogField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool obscure = false,
  TextInputType? keyboard,
  Widget? suffix,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboard,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      errorStyle: const TextStyle(fontSize: 11),
    ),
  );
}

// ── Section card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                if (action != null) ...[const Spacer(), action!],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

// ── Info row ───────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool mono;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFamily: mono ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
