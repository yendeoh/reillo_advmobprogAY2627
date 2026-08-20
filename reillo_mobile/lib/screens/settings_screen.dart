import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

// Enhancement 3: Add a settings page to host the dark/light mode switch.

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
        ],
      ),
    );
  }
}
