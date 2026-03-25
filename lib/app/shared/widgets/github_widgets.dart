import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../theme/github_theme.dart';
import '../../theme/theme_controller.dart';

class GithubTopBar extends StatelessWidget implements PreferredSizeWidget {
  const GithubTopBar({
    super.key,
    required this.title,
    this.onLogout,
  });

  final String title;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final List<String> notifications = <String>[
      'Medication reminder: 8:00 PM',
      'New appointment tomorrow 10:30 AM',
      'Your medical report was updated',
    ];
    final ThemeController themeController = Get.find<ThemeController>();
    final bool isDark = themeController.themeMode.value == ThemeMode.dark;

    return AppBar(
      title: Row(
        children: <Widget>[
          const Icon(Icons.local_hospital_outlined, size: 20),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      actions: <Widget>[
        IconButton(
          tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
          onPressed: themeController.toggleThemeMode,
          icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
        ),
        if (onLogout != null)
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.notifications_none_rounded),
          itemBuilder: (BuildContext context) {
            return notifications
                .map(
                  (String item) => PopupMenuItem<String>(
                    enabled: false,
                    child: SizedBox(width: 280, child: Text(item)),
                  ),
                )
                .toList();
          },
        ),
        const SizedBox(width: 6),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: GithubTheme.border),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(57);
}

class GithubSectionHeader extends StatelessWidget {
  const GithubSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.showDivider = true,
  });

  final String title;
  final String subtitle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: GithubTheme.border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: GithubTheme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class GithubBadge extends StatelessWidget {
  const GithubBadge({
    super.key,
    required this.text,
    required this.textColor,
    required this.bgColor,
  });

  final String text;
  final Color textColor;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class GithubFeatureCard extends StatelessWidget {
  const GithubFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionText,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: GithubTheme.textSecondary),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: GithubTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: onTap, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}

class PatientSidebarCard extends StatelessWidget {
  const PatientSidebarCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Patient Portal', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 10),
            SidebarLink(icon: Icons.calendar_month_outlined, text: 'Appointments'),
            SizedBox(height: 4),
            SidebarLink(icon: Icons.description_outlined, text: 'Medical Reports'),
            SizedBox(height: 4),
            SidebarLink(
              icon: Icons.volunteer_activism_outlined,
              text: 'Health Guidance',
            ),
          ],
        ),
      ),
    );
  }
}

class SidebarLink extends StatelessWidget {
  const SidebarLink({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Icon(icon, size: 18, color: GithubTheme.textSecondary),
      title: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
