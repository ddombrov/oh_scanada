import 'package:flutter/material.dart';
import '../../colours/colour_system.dart';

// social interaction button
Widget buildInteractionButton({
  required IconData icon,
  required int count,
  required String label,
  Color? iconColor,
  required Color textColor,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    mouseCursor: SystemMouseCursors.click,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: _buildInteractionContent(
          icon: icon,
          iconSize: 16,
          count: count,
          label: label,
          iconColor: iconColor ?? CanadianTheme.canadianRed,
          textColor: textColor,
          showLabel: true),
    ),
  );
}

// small like button for comments
Widget buildSmallInteractionButton({
  required IconData icon,
  required int count,
  Color? iconColor,
  required Color textColor,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: _buildInteractionContent(
        icon: icon,
        iconSize: 14,
        count: count,
        iconColor: iconColor ?? CanadianTheme.canadianRed,
        textColor: textColor,
        showLabel: false),
  );
}

// shared button content generator
Widget _buildInteractionContent({
  required IconData icon,
  required double iconSize,
  required int count,
  String? label,
  required Color iconColor,
  required Color textColor,
  required bool showLabel,
}) {
  return Row(
    children: [
      Icon(icon, size: iconSize, color: iconColor),
      const SizedBox(width: 4.0),
      Text(
        '$count',
        style: CanadianTheme.canadianText(fontSize: 12, color: textColor),
      ),
      if (showLabel && label != null) ...[
        const SizedBox(width: 4.0),
        Text(
          label,
          style: CanadianTheme.canadianText(fontSize: 12, color: textColor),
        ),
      ]
    ],
  );
}
