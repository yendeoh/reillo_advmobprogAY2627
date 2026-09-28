// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/validators.dart';
import 'signin_screen.dart';

// ENHANCEMENT 3: Reads the saved typed User from UserService and renders the
// account identity, contact details, and session controls in a profile UI.
// LAB ACT 5 - ENHANCEMENT 3: The details shown depend on the LoginType, and
// the account section can update the username, change the password, delete
// the account, and log out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _userService.getUser();
  }

  void _reload() {
    // Block body: an arrow here would return the Future, which setState rejects.
    setState(() {
      _userFuture = _userService.getUser();
    });
  }

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    _goToSignIn();
  }

  void _goToSignIn() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SigninScreen()),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateUsername(User user) async {
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _AccountFormDialog(
        title: 'Update username',
        actionLabel: 'Save',
        fields: [
          _FieldSpec(
            key: 'username',
            label: 'New username',
            initialValue: user.username,
            validator: Validators.username,
          ),
        ],
      ),
    );
    if (values == null) return;

    try {
      await _userService.changeUsername(user, values['username']!.trim());
      if (!mounted) return;
      _showMessage('Username updated.');
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Update failed: ${UserService.errorMessage(e)}');
    }
  }

  Future<void> _changePassword(User user) async {
    final isFirebase = user.loginType == LoginType.firebase;
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _AccountFormDialog(
        title: 'Change password',
        actionLabel: 'Change',
        fields: [
          // Firebase re-authenticates with the current password first.
          if (isFirebase)
            _FieldSpec(
              key: 'current',
              label: 'Current password',
              obscure: true,
              validator: (value) =>
                  Validators.required(value, 'Current password'),
            ),
          _FieldSpec(
            key: 'new',
            label: 'New password',
            obscure: true,
            validator: Validators.password,
          ),
          _FieldSpec(
            key: 'confirm',
            label: 'Confirm new password',
            obscure: true,
            matches: 'new',
          ),
        ],
      ),
    );
    if (values == null) return;

    try {
      await _userService.changePassword(
        user,
        currentPassword: values['current'] ?? '',
        newPassword: values['new']!,
      );
      if (!mounted) return;
      _showMessage('Password changed.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Change failed: ${UserService.errorMessage(e)}');
    }
  }

  Future<void> _deleteAccount(User user) async {
    final isFirebase = user.loginType == LoginType.firebase;
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _AccountFormDialog(
        title: 'Delete account?',
        message: isFirebase
            ? 'This permanently deletes your Firebase account. Enter your '
                  'password to confirm.'
            : 'DummyJSON will simulate deleting this user and you will be '
                  'logged out.',
        actionLabel: 'Delete',
        destructive: true,
        fields: [
          if (isFirebase)
            _FieldSpec(
              key: 'password',
              label: 'Password',
              obscure: true,
              validator: (value) => Validators.required(value, 'Password'),
            ),
        ],
      ),
    );
    if (values == null) return;

    try {
      await _userService.removeAccount(
        user,
        password: values['password'] ?? '',
      );
      if (!mounted) return;
      _showMessage('Account deleted.');
      _goToSignIn();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Delete failed: ${UserService.errorMessage(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('No saved user data found.'));
          }

          final user = snapshot.data!;
          final isFirebase = user.loginType == LoginType.firebase;

          return SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                  decoration: const BoxDecoration(
                    color: Color(0xFF202B62),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'My profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: user.image.isNotEmpty
                                    ? NetworkImage(user.image)
                                    : null,
                                child: user.image.isEmpty
                                    ? const Icon(Icons.person, size: 40)
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName
                                    : user.username,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '@${user.username}',
                                style: const TextStyle(color: Colors.orange),
                              ),
                              const SizedBox(height: 12),
                              Chip(
                                avatar: Icon(
                                  isFirebase
                                      ? Icons.local_fire_department_outlined
                                      : Icons.cloud_outlined,
                                  size: 18,
                                  color: const Color(0xFF202B62),
                                ),
                                label: Text(
                                  'Signed in with ${user.loginType.label}',
                                ),
                                backgroundColor: const Color(0xFFFFF3D6),
                                side: BorderSide.none,
                              ),
                            ],
                          ),
                        ),
                      ),
                      _Section(
                        children: [
                          _InfoRow(
                            icon: Icons.email,
                            label: 'Email',
                            value: user.email,
                          ),
                          if (isFirebase) ...[
                            _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'Age',
                              value: user.age > 0 ? '${user.age}' : '—',
                            ),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Contact no.',
                              value: user.phone.isNotEmpty ? user.phone : '—',
                            ),
                            _InfoRow(
                              icon: Icons.fingerprint,
                              label: 'Firebase UID',
                              value: user.uid,
                            ),
                          ] else ...[
                            _InfoRow(
                              icon: Icons.wc,
                              label: 'Gender',
                              value: user.gender,
                            ),
                            _InfoRow(
                              icon: Icons.badge,
                              label: 'User ID',
                              value: '#${user.id}',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Account',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      _Section(
                        children: [
                          _ActionRow(
                            icon: Icons.edit_outlined,
                            label: 'Update username',
                            onTap: () => _updateUsername(user),
                          ),
                          _ActionRow(
                            icon: Icons.lock_reset,
                            label: 'Change password',
                            onTap: () => _changePassword(user),
                          ),
                          _ActionRow(
                            icon: Icons.delete_outline,
                            label: 'Delete account',
                            destructive: true,
                            onTap: () => _deleteAccount(user),
                          ),
                        ],
                      ),
                      if (!isFirebase)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
                          child: Text(
                            'DummyJSON only simulates these changes; they are '
                            'not saved on the server.',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF202B62),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// White rounded card with dividers between its rows.
class _Section extends StatelessWidget {
  final List<Widget> children;

  const _Section({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Text(label),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red.shade700 : Colors.black87;
    return ListTile(
      leading: Icon(
        icon,
        color: destructive ? Colors.red.shade700 : Colors.amber,
      ),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
      onTap: onTap,
    );
  }
}

class _FieldSpec {
  final String key;
  final String label;
  final String initialValue;
  final bool obscure;
  final String? Function(String?)? validator;
  // Key of another field this one must equal (for confirm password).
  final String? matches;

  const _FieldSpec({
    required this.key,
    required this.label,
    this.initialValue = '',
    this.obscure = false,
    this.validator,
    this.matches,
  });
}

/// Dialog with a small validated form. Pops with the field values, or null
/// when cancelled.
class _AccountFormDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String actionLabel;
  final bool destructive;
  final List<_FieldSpec> fields;

  const _AccountFormDialog({
    required this.title,
    required this.actionLabel,
    required this.fields,
    this.message,
    this.destructive = false,
  });

  @override
  State<_AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<_AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final field in widget.fields)
      field.key: TextEditingController(text: field.initialValue),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      for (final entry in _controllers.entries) entry.key: entry.value.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.message != null) Text(widget.message!),
              for (final field in widget.fields)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: _controllers[field.key],
                    autofocus: field == widget.fields.first,
                    obscureText: field.obscure,
                    decoration: InputDecoration(labelText: field.label),
                    validator: field.matches == null
                        ? field.validator
                        : (value) => Validators.confirmPassword(
                            value,
                            _controllers[field.matches]!.text,
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: widget.destructive
              ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700)
              : null,
          onPressed: _submit,
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
