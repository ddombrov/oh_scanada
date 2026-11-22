import 'community_api.dart';

// Comments on community posts, stored by the Worker in D1.
class CommentService {
  Future<List<Map<String, dynamic>>> getCommentsForPost(String postId) async {
    try {
      final rows = await CommunityApi.get('/api/posts/$postId/comments') as List;
      return rows.map(CommunityApi.toComment).toList();
    } catch (e) {
      print('error getting comments: $e');
      return [];
    }
  }

  Future<void> toggleCommentLike(String commentId) => CommunityApi.post('/api/comments/$commentId/like');

  Future<String> addComment({required String content, required String postId}) async {
    final result = await CommunityApi.post('/api/posts/$postId/comments', {'content': content});
    return result['id'] as String;
  }

  Future<void> deleteComment(String commentId) => CommunityApi.post('/api/comments/$commentId/delete');
}
