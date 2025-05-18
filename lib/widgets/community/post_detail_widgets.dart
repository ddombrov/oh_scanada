import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../page_section.dart';
import '../../colours/colour_system.dart';
import 'interaction_widgets.dart';

// post detail widget
Widget buildPostDetails({
  required BuildContext context,
  required Map<String, dynamic> post,
  required String username,
  required bool isDarkMode,
  required VoidCallback onLike,
  required VoidCallback onShare,
}) {
  final textColor = isDarkMode ? Colors.white : CanadianTheme.darkGrey;
  final secondaryTextColor = isDarkMode
      ? Colors.white70
      : CanadianTheme.darkGrey.withValues(alpha: 0.7);
  String userInitial =
      username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?';

  return buildSection(
    title: "post",
    icon: Icons.article,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // user info
        buildAuthorInfo(
          username: username,
          userInitial: userInitial,
          timestamp: _getPostTimestamp(post),
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        const SizedBox(height: 12.0),

        // post text
        Text(
          post['content']?.toString() ?? '',
          style: CanadianTheme.canadianText(
            fontSize: 16,
            height: 1.5,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16.0),

        // action buttons
        Row(
          children: [
            // like button
            buildInteractionButton(
              icon: post['is_liked'] ?? false
                  ? Icons.thumb_up
                  : Icons.thumb_up_outlined,
              count: post['likes'] ?? 0,
              label: 'like',
              iconColor: (post['is_liked'] ?? false)
                  ? Colors.red
                  : CanadianTheme.canadianRed,
              textColor: secondaryTextColor,
              onTap: onLike,
            ),
            const SizedBox(width: 16.0),

            // comment button
            buildInteractionButton(
              icon: Icons.comment_outlined,
              count: post['comments'] ?? 0,
              label: 'comment',
              textColor: secondaryTextColor,
              onTap: () {
                // focus handled in parent
              },
            ),
            const SizedBox(width: 16.0),

            // share button
            buildInteractionButton(
              icon: Icons.share_outlined,
              count: post['shares'] ?? 0,
              label: 'share',
              textColor: secondaryTextColor,
              onTap: onShare,
            ),
          ],
        ),
      ],
    ),
  );
}

// post author component
Widget buildAuthorInfo({
  required String username,
  required String userInitial,
  required DateTime timestamp,
  required Color textColor,
  required Color secondaryTextColor,
}) {
  return Row(
    children: [
      // avatar
      CircleAvatar(
        radius: 24,
        backgroundColor: CanadianTheme.canadianRed.withValues(alpha: 0.2),
        child: Text(
          userInitial,
          style: CanadianTheme.canadianText(
            color: CanadianTheme.canadianRed,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      const SizedBox(width: 12.0),

      // name and time
      Expanded(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              username,
              style: CanadianTheme.canadianText(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8.0),
            Text("•", style: TextStyle(color: textColor)),
            const SizedBox(width: 8.0),
            Text(
              Helpers.formatRelativeTime(timestamp),
              style: CanadianTheme.canadianText(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// extract timestamp
DateTime _getPostTimestamp(Map<String, dynamic> post) {
  final createdAt = post['createdAt'];
  if (createdAt is Timestamp) return createdAt.toDate();
  if (createdAt is DateTime) return createdAt;
  return DateTime.now();
}
