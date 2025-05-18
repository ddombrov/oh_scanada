import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/helpers.dart';
import '../page_section.dart';
import '../../colours/colour_system.dart';
import 'interaction_widgets.dart';

// comments section widget
Widget buildCommentsSection({
  required BuildContext context,
  required List<Map<String, dynamic>> comments,
  required TextEditingController commentController,
  required bool isLoading,
  required bool isDarkMode,
  required VoidCallback onAddComment,
  required Function(int) onLikeComment,
}) {
  final textColor = isDarkMode ? Colors.white : CanadianTheme.darkGrey;
  final secondaryTextColor = isDarkMode
      ? Colors.white70
      : CanadianTheme.darkGrey.withValues(alpha: .7);

  return buildSection(
    title: "Comments",
    icon: Icons.chat_bubble_outline,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // comment input box
        _buildCommentInput(
          commentController: commentController,
          textColor: textColor,
          isDarkMode: isDarkMode,
          onSend: onAddComment,
        ),
        const SizedBox(height: 20.0),

        // comments list
        _buildCommentsContent(
          comments: comments,
          isLoading: isLoading,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
          isDarkMode: isDarkMode,
          onLikeComment: onLikeComment,
        ),
      ],
    ),
  );
}

// comments list with loading state
Widget _buildCommentsContent({
  required List<Map<String, dynamic>> comments,
  required bool isLoading,
  required Color textColor,
  required Color secondaryTextColor,
  required bool isDarkMode,
  required Function(int) onLikeComment,
}) {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (comments.isEmpty) {
    return Center(
      child: Text(
        'no comments yet',
        style: CanadianTheme.canadianText(color: secondaryTextColor),
      ),
    );
  }

  return Column(
    children: [
      ...comments
          .asMap()
          .entries
          .map((entry) => _buildCommentItem(
                comment: entry.value,
                index: entry.key,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                isDarkMode: isDarkMode,
                onLike: () => onLikeComment(entry.key),
              ))
          .toList(),

      // view more button
      if (comments.length > 3)
        Center(
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add_comment,
                color: CanadianTheme.canadianRed, size: 16),
            label: Text(
              'view more comments',
              style: CanadianTheme.canadianText(
                color: CanadianTheme.canadianRed,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
    ],
  );
}

// comment input field
Widget _buildCommentInput({
  required TextEditingController commentController,
  required Color textColor,
  required bool isDarkMode,
  required VoidCallback onSend,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    decoration: BoxDecoration(
      color: isDarkMode ? const Color(0xFF252525) : Colors.white,
      borderRadius: BorderRadius.circular(8.0),
      border: Border.all(
        color: isDarkMode ? Colors.white12 : CanadianTheme.lightGrey,
      ),
    ),
    child: Row(
      children: [
        // user avatar
        CircleAvatar(
          radius: 16,
          backgroundColor: CanadianTheme.canadianRed.withAlpha(51),
          child: const Text(
            'Y', // you
            style: TextStyle(
              color: CanadianTheme.canadianRed,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8.0),

        // text field
        Expanded(
          child: TextField(
            controller: commentController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'add a comment...',
              hintStyle: CanadianTheme.canadianText(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
          ),
        ),

        // send button
        IconButton(
          icon: const Icon(Icons.send, color: CanadianTheme.canadianRed),
          onPressed: onSend,
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          iconSize: 20,
        ),
      ],
    ),
  );
}

// single comment display
Widget _buildCommentItem({
  required Map<String, dynamic> comment,
  required int index,
  required Color textColor,
  required Color secondaryTextColor,
  required bool isDarkMode,
  required VoidCallback onLike,
}) {
  // get data from comment
  final commentUsername = comment['username'] ?? 'unknown user';
  final userInitial = commentUsername.isNotEmpty
      ? commentUsername.substring(0, 1).toUpperCase()
      : '?';
  final isLiked = comment['is_liked'] ?? false;

  // timestamp handling
  final commentTimestamp = comment['createdAt'] is Timestamp
      ? (comment['createdAt'] as Timestamp).toDate()
      : DateTime.now();

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // avatar circle
            CircleAvatar(
              radius: 16,
              backgroundColor: CanadianTheme.canadianRed.withAlpha(51),
              child: Text(
                userInitial,
                style: CanadianTheme.canadianText(
                  color: CanadianTheme.canadianRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8.0),

            // comment body
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // username and time
                  Row(
                    children: [
                      Text(
                        commentUsername,
                        style: CanadianTheme.canadianText(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        Helpers.formatRelativeTime(commentTimestamp),
                        style: CanadianTheme.canadianText(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),

                  // comment text
                  Text(
                    comment['content']?.toString() ?? '',
                    style: CanadianTheme.canadianText(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4.0),

                  // like & reply buttons
                  Row(
                    children: [
                      // like button
                      buildSmallInteractionButton(
                        icon:
                            isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        count: comment['likes'] ?? 0,
                        iconColor:
                            isLiked ? Colors.red : CanadianTheme.canadianRed,
                        textColor: secondaryTextColor,
                        onTap: onLike,
                      ),
                      const SizedBox(width: 12.0),

                      // reply button
                      InkWell(
                        onTap: () {},
                        child: Text(
                          'reply',
                          style: CanadianTheme.canadianText(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Divider(
          color: isDarkMode ? Colors.white12 : CanadianTheme.lightGrey,
          height: 1.0),
    ],
  );
}
