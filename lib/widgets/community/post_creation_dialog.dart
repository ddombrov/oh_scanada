import 'package:flutter/material.dart';
import '../../services/post_service.dart';
import '../../colours/colour_system.dart';

// post creation dialog
void showCreatePostDialog({
  required BuildContext context,
  required bool isDarkMode,
  required Color textColor,
  required PostService postService,
  required VoidCallback onPostCreated,
}) {
  final TextEditingController contentController = TextEditingController();
  final TextEditingController titleController = TextEditingController();

  final bgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: bgColor,
      title: Text(
        'create new post',
        style: CanadianTheme.canadianText(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // title field (optional)
          _buildTextField(
            controller: titleController,
            hintText: 'title (optional)',
            maxLines: 1,
            isDarkMode: isDarkMode,
            textColor: textColor,
          ),
          const SizedBox(height: 16),

          // main content
          _buildTextField(
            controller: contentController,
            hintText: 'what would you like to share?',
            maxLines: 4,
            isDarkMode: isDarkMode,
            textColor: textColor,
          ),
        ],
      ),
      actions: [
        // cancel button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'cancel',
              style: CanadianTheme.canadianText(
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
        ),

        // post button
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: ElevatedButton(
            onPressed: () => _submitPost(
              context: context,
              contentController: contentController,
              titleController: titleController,
              postService: postService,
              onPostCreated: onPostCreated,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: CanadianTheme.canadianRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6.0),
              ),
            ),
            child: Text(
              'post',
              style: CanadianTheme.canadianText(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// custom text field
Widget _buildTextField({
  required TextEditingController controller,
  required String hintText,
  required int maxLines,
  required bool isDarkMode,
  required Color textColor,
}) {
  return TextField(
    controller: controller,
    style: TextStyle(color: textColor),
    maxLines: maxLines,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: textColor.withValues(alpha: 0.6)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: CanadianTheme.canadianRed, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
            color: isDarkMode
                ? Colors.white24
                : CanadianTheme.darkGrey.withAlpha(77),
            width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      contentPadding: const EdgeInsets.all(12.0),
    ),
  );
}

// add post to firebase
void _submitPost({
  required BuildContext context,
  required TextEditingController contentController,
  required TextEditingController titleController,
  required PostService postService,
  required VoidCallback onPostCreated,
}) async {
  // make sure we have content
  if (contentController.text.trim().isNotEmpty) {
    try {
      await postService.addPost(
        contentController.text.trim(),
        titleController.text.trim(),
      );
      Navigator.pop(context);

      // refresh the posts list
      onPostCreated();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('post created!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error creating post: $e')),
      );
    }
  }
}
