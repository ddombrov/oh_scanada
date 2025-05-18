import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/post_service.dart';
import '../services/comment_service.dart';
import '../widgets/screen_layout.dart';
import '../widgets/page_title.dart';
import '../widgets/community/post_detail_widgets.dart';
import '../widgets/community/comment_widgets.dart';
import '../colours/colour_system.dart';

class PostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostScreen({super.key, required this.post});
  @override
  _PostScreenState createState() => _PostScreenState();
}

class _PostScreenState extends State<PostScreen> {
  final PostService _postService = PostService();
  final CommentService _commentService = CommentService();
  final TextEditingController _commentController = TextEditingController();
  final _themeProvider = ThemeProvider();

  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  String _username = 'Unknown User';
  late Map<String, dynamic> _post;

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_themeListener);
    _post = Map<String, dynamic>.from(widget.post);
    _fetchUserAndComments();
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_themeListener);
    super.dispose();
  }

  void _themeListener() {
    if (mounted) setState(() {});
  }

  bool get _isDarkMode => _themeProvider.isDarkMode;
  Color get _bgColor =>
      _isDarkMode ? const Color(0xFF121212) : CanadianTheme.offWhite;

  void _fetchUserAndComments() async {
    try {
      setState(() => _isLoading = true);

      // get username
      if (widget.post['post_owner'] is DocumentReference) {
        final userData =
            await _postService.getUserFromReference(widget.post['post_owner']);
        if (userData != null) {
          setState(() => _username =
              userData['name'] ?? userData['username'] ?? 'Unknown User');
        }
      } else if (widget.post['username'] is String) {
        setState(() => _username = widget.post['username']);
      }

      // get comments for post
      DocumentReference postRef =
          FirebaseFirestore.instance.collection('posts').doc(widget.post['id']);
      final comments =
          await _commentService.getCommentsForPostWithLikeStatus(postRef);

      // add usernames to comments
      final enrichedComments = await Future.wait(comments.map((comment) async {
        final enrichedComment = Map<String, dynamic>.from(comment);
        if (comment['comment_owner'] is DocumentReference) {
          final userData =
              await _postService.getUserFromReference(comment['comment_owner']);
          enrichedComment['username'] =
              userData?['name'] ?? userData?['username'] ?? 'Unknown User';
        }
        return enrichedComment;
      }));

      setState(() {
        _comments = enrichedComments;
        _isLoading = false;
      });
    } catch (e) {
      print('error fetching comments: $e');
      setState(() => _isLoading = false);
    }
  }

  // handle optimistic updates
  Future<void> _optimisticUpdate(
      {required String type, required bool isUpdate, int? commentIndex}) async {
    try {
      if (type == 'post_like') {
        // like/unlike post
        final wasLiked = _post['is_liked'] ?? false;
        setState(() {
          _post['is_liked'] = !wasLiked;
          _post['likes'] = (_post['likes'] ?? 0) + (wasLiked ? -1 : 1);
        });

        // update in db
        await _postService.togglePostLike(_post['id']);
      } else if (type == 'comment_like' && commentIndex != null) {
        // like/unlike comment
        final comment = _comments[commentIndex];
        final wasLiked = comment['is_liked'] ?? false;

        setState(() {
          comment['is_liked'] = !wasLiked;
          comment['likes'] = (comment['likes'] ?? 0) + (wasLiked ? -1 : 1);
          _comments[commentIndex] = Map<String, dynamic>.from(comment);
        });

        // update in db
        await _commentService.toggleCommentLike(comment['id']);
      } else if (type == 'share') {
        // share post
        setState(() => _post['shares'] = (_post['shares'] ?? 0) + 1);
        await _postService.updateInteraction(_post['id'], 'shares');
      }
    } catch (e) {
      // revert on error
      if (type == 'post_like') {
        setState(() {
          _post['is_liked'] = !(_post['is_liked'] ?? false);
          _post['likes'] = (_post['likes'] ?? 0) + (_post['is_liked'] ? 1 : -1);
        });
      } else if (type == 'comment_like' && commentIndex != null) {
        final comment = _comments[commentIndex];
        setState(() {
          comment['is_liked'] = !(comment['is_liked'] ?? false);
          comment['likes'] =
              (comment['likes'] ?? 0) + (comment['is_liked'] ? 1 : -1);
          _comments[commentIndex] = Map<String, dynamic>.from(comment);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('error updating $type: $e')),
      );
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      DocumentReference postRef =
          FirebaseFirestore.instance.collection('posts').doc(widget.post['id']);
      await _commentService.addComment(
          content: _commentController.text.trim(), postRef: postRef);
      _commentController.clear();
      _fetchUserAndComments();
      setState(() => _post['comments'] = (_post['comments'] ?? 0) + 1);
    } catch (e) {
      print('error adding comment: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('failed to add comment: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenLayout(
      body: Container(
        color: _bgColor,
        child: Column(
          children: [
            buildTitle("Post Details"),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      buildPostDetails(
                        context: context,
                        post: _post,
                        username: _username,
                        isDarkMode: _isDarkMode,
                        onLike: () => _optimisticUpdate(
                            type: 'post_like', isUpdate: true),
                        onShare: () =>
                            _optimisticUpdate(type: 'share', isUpdate: true),
                      ),
                      const SizedBox(height: 16.0),
                      buildCommentsSection(
                        context: context,
                        comments: _comments,
                        commentController: _commentController,
                        isLoading: _isLoading,
                        isDarkMode: _isDarkMode,
                        onAddComment: _addComment,
                        onLikeComment: (index) => _optimisticUpdate(
                            type: 'comment_like',
                            isUpdate: true,
                            commentIndex: index),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
