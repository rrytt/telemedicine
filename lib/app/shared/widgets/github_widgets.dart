import 'package:flutter/material.dart';
import 'package:get/get.dart';

const Color _accentSlate = Color(0xFF4A627A);
const Color _borderLight = Color(0xFFE2E8F0);
const Color _darkSurface = Color(0xFF1E293B);
const Color _darkBorder = Color(0xFF334155);
const Color _darkTextSecondary = Color(0xFF94A3B8);
const Color _darkTextPrimary = Color(0xFFF1F5F9);
const Color _white = Color(0xFFFFFFFF);

bool get _isDark => Get.isDarkMode;

Color get _textSecondary => _isDark ? _darkTextSecondary : _accentSlate;
Color get _textPrimary => _isDark ? _darkTextPrimary : const Color(0xFF1A3A5C);
Color get _border => _isDark ? _darkBorder : _borderLight;
Color get _surface => _isDark ? _darkSurface : _white;

class InboxNotificationItem {
  const InboxNotificationItem({
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    this.unread = false,
  });

  final String title;
  final String description;
  final String time;
  final String type;
  final bool unread;
}

class GithubTopBar extends StatelessWidget implements PreferredSizeWidget {
  const GithubTopBar({super.key, required this.title, this.onLogout});

  final String title;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final List<InboxNotificationItem> notifications = <InboxNotificationItem>[
      const InboxNotificationItem(
        title: 'Medication reminder',
        description: 'Take Metformin 500mg at 8:00 PM',
        time: '5m ago',
        type: 'Reminder',
        unread: true,
      ),
      const InboxNotificationItem(
        title: 'New appointment request',
        description: 'Tomorrow at 10:30 AM with Dr. Sarah',
        time: '24m ago',
        type: 'Appointment',
        unread: true,
      ),
      const InboxNotificationItem(
        title: 'Lab report uploaded',
        description: 'CBC results are available for review',
        time: '1h ago',
        type: 'Report',
      ),
    ];

    return AppBar(
      title: Row(
        children: <Widget>[
          Image.asset('assets/images/icon.jpg', width: 20, height: 20, fit: BoxFit.cover),
          const SizedBox(width: 8),
          Flexible(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      actions: <Widget>[
        if (onLogout != null)
          TextButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Logout'),
          ),
        PopupMenuButton<InboxNotificationItem>(
          icon: const Icon(Icons.notifications_none_rounded),
          constraints: const BoxConstraints(minWidth: 360, maxWidth: 360),
          itemBuilder: (BuildContext context) {
            return <PopupMenuEntry<InboxNotificationItem>>[
              const PopupMenuItem<InboxNotificationItem>(
                enabled: false,
                padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.inbox_outlined, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Notifications Inbox',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              ...notifications.map(
                (InboxNotificationItem item) =>
                    PopupMenuItem<InboxNotificationItem>(
                      enabled: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            item.type == 'Reminder'
                                ? Icons.alarm_outlined
                                : item.type == 'Appointment'
                                ? Icons.event_outlined
                                : Icons.description_outlined,
                            size: 16,
                            color: _textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (item.unread)
                                      GithubBadge(
                                        text: 'New',
                                        textColor: const Color(0xFF4ECDC4),
                                        bgColor: _isDark ? const Color(0xFF1E293B) : const Color(0xFFDDF4FF),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.time,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ];
          },
        ),
        const SizedBox(width: 6),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: _border),
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
            ? Border(bottom: BorderSide(color: _border))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
            ),
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
            Icon(icon, color: _textSecondary),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: _textPrimary)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: _textSecondary),
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
            Text(
              'Patient Portal',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            SidebarLink(
              icon: Icons.calendar_month_outlined,
              text: 'Appointments',
            ),
            SizedBox(height: 4),
            SidebarLink(
              icon: Icons.description_outlined,
              text: 'Medical Reports',
            ),
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
      leading: Icon(icon, size: 18, color: _textSecondary),
      title: Text(text, style: TextStyle(fontSize: 14, color: _textPrimary)),
    );
  }
}

class GithubDrawerItem {
  const GithubDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class GithubDrawer extends StatelessWidget {
  const GithubDrawer({super.key, required this.menuTitle, required this.items});

  final String menuTitle;
  final List<GithubDrawerItem> items;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF4ECDC4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/icon.jpg', width: 48, height: 48, fit: BoxFit.cover),
                ),
                const SizedBox(height: 12),
                Text(
                  menuTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...items.map(
            (GithubDrawerItem item) => ListTile(
              leading: Icon(item.icon, color: _textSecondary),
              title: Text(item.label, style: TextStyle(color: _textPrimary)),
              onTap: () {
                Get.back();
                item.onTap();
              },
            ),
          ),
        ],
      ),
    );
  }
}
