// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'signin_screen.dart';

// ENHANCEMENT 3: Reads the saved typed User from UserService and renders the
// account identity, contact details, and session controls in a profile UI.
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

  Future<void> _logout() async {
    await _userService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SigninScreen()),
      (route) => false,
    );
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 0),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.email,
                              label: 'Email',
                              value: user.email,
                            ),
                            const Divider(height: 1),
                            _InfoRow(
                              icon: Icons.wc,
                              label: 'Gender',
                              value: user.gender,
                            ),
                            const Divider(height: 1),
                            _InfoRow(
                              icon: Icons.badge,
                              label: 'User ID',
                              value: '#${user.id}',
                            ),
                          ],
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
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
