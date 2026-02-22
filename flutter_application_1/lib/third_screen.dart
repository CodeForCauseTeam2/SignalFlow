import 'package:flutter/material.dart';

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    // Use actual theme brightness so the switch updates when we toggle (works both ways)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "Appearance",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text("Dark mode"),
            subtitle: Text(isDark ? "Dark theme on" : "Light theme on"),
            value: isDark,
            onChanged: (value) {
              onThemeModeChanged(value ? ThemeMode.dark : ThemeMode.light);
            },
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              "About",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            title: const Text("SignFlow"),
            subtitle: const Text("Sign-to-text for accessibility"),
            leading: Icon(Icons.accessibility_new, color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
