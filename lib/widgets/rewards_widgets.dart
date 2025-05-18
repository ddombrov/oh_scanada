import 'package:flutter/material.dart';
import '../widgets/progress_bar.dart';
import '../widgets/page_section.dart';
import '../colours/colour_system.dart';

// Builds the rewards section for the community screen
Widget buildRewardsSection({
  required int currentPoints,
  required int nextRewardLevel,
  required String currentBadge,
  required String nextBadge,
  required bool isDarkMode,
  required Color textColor,
  required Color secondaryTextColor,
}) {
  return buildSection(
    title: "Your Rewards",
    icon: Icons.card_giftcard,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildProgressBar(currentPoints, nextRewardLevel),
        const SizedBox(height: 8.0),
        Text(
          'Your reward: $currentBadge',
          style: CanadianTheme.canadianText(
            fontSize: 14,
            color: textColor,
          ),
        ),
        Text(
          'Upcoming Reward: $nextBadge',
          style: CanadianTheme.canadianText(
            fontSize: 12,
            color: secondaryTextColor,
          ),
        ),
      ],
    ),
  );
}
