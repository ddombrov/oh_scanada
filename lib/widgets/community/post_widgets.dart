import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../../colours/colour_system.dart';

// tag for own posts
Widget buildPostTag(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: CanadianTheme.canadianRed.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        text,
        style: CanadianTheme.canadianText(
          color: CanadianTheme.canadianRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

// user avatar circle
Widget buildUserAvatar(String username, {double radius = 18.0}) => CircleAvatar(
      radius: radius,
      backgroundColor: CanadianTheme.canadianRed.withAlpha(51),
      child: Text(
        username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?',
        style: CanadianTheme.canadianText(
          color: CanadianTheme.canadianRed,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );

// post title (optional)
Widget buildPostTitle({required String? title, required Color textColor}) {
  if (title == null || title.isEmpty) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      title,
      style: CanadianTheme.canadianText(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
  );
}

// post body text
Widget buildPostContent({
  required String content,
  required Color textColor,
  required VoidCallback onTap,
}) =>
    InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        child: Text(
          content,
          style: CanadianTheme.canadianText(
            fontSize: 14,
            height: 1.4,
            color: textColor,
          ),
        ));

// post data packaging
Map<String, dynamic> createCompletePostObject(
        Map<String, dynamic> post, String username) =>
    {
      'id': post['id'],
      'content': post['content'] ?? '',
      'title': post['title'] ?? '',
      'likes': post['likes'] ?? 0,
      'comments': post['comments'] ?? 0,
      'shares': post['shares'] ?? 0,
      'createdAt': post['createdAt'],
      'username': username,
      'post_owner': post['post_owner'],
      'is_liked': post['is_liked'] ?? false,
    };

// post header with user info
Widget buildPostHeader({
  required Map<String, dynamic> post,
  required String username,
  required bool isUserPost,
  required bool isCurrentUserPost,
  required Color textColor,
  required Color secondaryTextColor,
  required VoidCallback onTap,
}) {
  // get timestamp
  DateTime? timestamp;
  if (post['createdAt'] is Timestamp) {
    timestamp = (post['createdAt'] as Timestamp).toDate();
  } else if (post['createdAt'] is DateTime) {
    timestamp = post['createdAt'] as DateTime;
  }
  final timeAgo =
      timestamp != null ? Helpers.formatRelativeTime(timestamp) : 'recently';

  return InkWell(
    onTap: onTap,
    mouseCursor: SystemMouseCursors.click,
    child: Row(
      children: [
        buildUserAvatar(username),
        const SizedBox(width: 8.0),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: CanadianTheme.canadianText(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8.0),
              Text("•", style: TextStyle(color: textColor)),
              const SizedBox(width: 8.0),
              Text(
                timeAgo,
                style: CanadianTheme.canadianText(
                  fontSize: 12,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
        if (isCurrentUserPost) buildPostTag('your post'),
      ],
    ),
  );
}
