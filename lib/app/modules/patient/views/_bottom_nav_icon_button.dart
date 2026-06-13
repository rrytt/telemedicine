import 'package:flutter/material.dart';

import '../../../theme/github_theme.dart';

class BottomNavIconButton extends StatelessWidget {
  const BottomNavIconButton({
    super.key,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color selectedColor = GithubTheme.primary;
    const Color unselectedColor = GithubTheme.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    selectedColor.withValues(alpha: 0.18),
                    selectedColor.withValues(alpha: 0.10),
                  ],
                )
              : null,
        ),
        child: Icon(
          icon,
          size: 26,
          color: isSelected ? selectedColor : unselectedColor,
        ),
      ),
    );
  }
}

