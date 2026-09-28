import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/user_service.dart';

// Enhancement 3: Add a settings page to host the dark/light mode switch.
// LAB ACT 5 - ENHANCEMENT 3: Settings also hosts Log out, which clears the
// session (and signs out of Firebase) and returns to the sign-in screen.

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await UserService().logout();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Switch between light and dark themes'),
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Current theme'),
            subtitle: Text(themeProvider.isDark ? 'Dark' : 'Light'),
            trailing: const Icon(Icons.palette_outlined),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            subtitle: const Text('Sign out and return to the login screen'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
