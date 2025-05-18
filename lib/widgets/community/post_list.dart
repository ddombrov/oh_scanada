import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screens/post_screen.dart';
import '../../services/post_service.dart';
import 'post_widgets.dart';
import 'interaction_widgets.dart';
import '../page_section.dart';

// posts display section
Widget buildPostsSection({
  required List<Map<String, dynamic>> posts,
  required bool isLoading,
  required bool isUserPosts,
  required IconData icon,
  required String title,
  required Color cardColor,
  required Color textColor,
  required Color secondaryTextColor,
  required PostService postService,
  required Function refreshPosts,
  required Function(String, Map<String, dynamic>) updatePost,
}) {
  return buildSection(
    title: title,
    icon: icon,
    child: _buildPostContent(
      posts: posts,
      isLoading: isLoading,
      isUserPosts: isUserPosts,
      cardColor: cardColor,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      postService: postService,
      refreshPosts: refreshPosts,
      updatePost: updatePost,
    ),
  );
}

// posts content with loading states
Widget _buildPostContent({
  required List<Map<String, dynamic>> posts,
  required bool isLoading,
  required bool isUserPosts,
  required Color cardColor,
  required Color textColor,
  required Color secondaryTextColor,
  required PostService postService,
  required Function refreshPosts,
  required Function(String, Map<String, dynamic>) updatePost,
}) {
  if (isLoading) {
    return const Center(child: CircularProgressIndicator());
  }

  if (posts.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'no posts yet',
          style: TextStyle(fontSize: 16, color: textColor),
        ),
      ),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(posts.length, (index) {
      final post = posts[index];

      // get user ref
      DocumentReference? userRef;
      if (post['post_owner'] is DocumentReference) {
        userRef = post['post_owner'] as DocumentReference;
      }

      if (userRef == null) return SizedBox.shrink();

      return FutureBuilder<Map<String, dynamic>?>(
        future: postService.getUserFromReference(userRef),
        builder: (context, userSnapshot) {
          String username = userSnapshot.hasData
              ? userSnapshot.data!['name'] ?? 'unknown'
              : userSnapshot.hasError
                  ? 'unknown user'
                  : 'loading...';

          return buildPostItem(
            context: context,
            post: post,
            username: username,
            isUserPost: isUserPosts,
            showDivider: index < posts.length - 1,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            postService: postService,
            refreshPosts: refreshPosts,
            updatePost: updatePost,
          );
        },
      );
    }),
  );
}

// individual post item
Widget buildPostItem({
  required BuildContext context,
  required Map<String, dynamic> post,
  required String username,
  required bool isUserPost,
  required bool showDivider,
  required Color cardColor,
  required Color textColor,
  required Color secondaryTextColor,
  required PostService postService,
  required Function refreshPosts,
  required Function(String, Map<String, dynamic>) updatePost,
}) {
  final postId = post['id'] as String;

  // check if this is user's own post
  bool isCurrentUserPost = false;
  if (post['post_owner'] is DocumentReference) {
    DocumentReference postOwnerRef = post['post_owner'] as DocumentReference;
    isCurrentUserPost = postOwnerRef.id == postService.currentUserId;
  }

  // action handlers
  void navigateToPostDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PostScreen(post: createCompletePostObject(post, username)),
      ),
    ).then((_) => refreshPosts());
  }

  void handleLike() async {
    try {
      // update UI first
      final updatedPost = Map<String, dynamic>.from(post);
      final wasLiked = updatedPost['is_liked'] ?? false;
      updatedPost['is_liked'] = !wasLiked;
      updatedPost['likes'] = (updatedPost['likes'] ?? 0) + (wasLiked ? -1 : 1);
      updatePost(postId, updatedPost);

      // then update db
      await postService.togglePostLike(postId);
    } catch (e) {
      // revert on error
      updatePost(postId, post);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error liking post: $e')),
      );
    }
  }

  void handleShare() async {
    try {
      await postService.updateInteraction(postId, 'shares');
      refreshPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error sharing post: $e')),
      );
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // post content
      buildPostTitle(title: post['title']?.toString(), textColor: textColor),
      buildPostHeader(
        post: post,
        username: username,
        isUserPost: isUserPost,
        isCurrentUserPost: isCurrentUserPost,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
        onTap: navigateToPostDetail,
      ),
      const SizedBox(height: 8.0),
      buildPostContent(
        content: post['content']?.toString() ?? '',
        textColor: textColor,
        onTap: navigateToPostDetail,
      ),
      const SizedBox(height: 12.0),

      // buttons
      Row(
        children: [
          buildInteractionButton(
            icon: post['is_liked'] ?? false
                ? Icons.thumb_up
                : Icons.thumb_up_outlined,
            count: post['likes'] ?? 0,
            label: 'like',
            iconColor: post['is_liked'] ?? false ? Colors.red : null,
            textColor: secondaryTextColor,
            onTap: handleLike,
          ),
          const SizedBox(width: 16.0),
          buildInteractionButton(
            icon: Icons.comment_outlined,
            count: post['comments'] ?? 0,
            label: 'comment',
            textColor: secondaryTextColor,
            onTap: navigateToPostDetail,
          ),
          const SizedBox(width: 16.0),
          buildInteractionButton(
            icon: Icons.share_outlined,
            count: post['shares'] ?? 0,
            label: 'share',
            textColor: secondaryTextColor,
            onTap: handleShare,
          ),
        ],
      ),

      // divider between posts
      if (showDivider)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Divider(
              height: 1.0,
              color: cardColor == Colors.white
                  ? Colors.grey[200]
                  : Colors.white24),
        ),
    ],
  );
}
