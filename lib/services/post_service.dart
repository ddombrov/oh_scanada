import 'community_api.dart';

// Community posts, stored by the Worker in D1.
class PostService {
  Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      final rows = await CommunityApi.get('/api/posts') as List;
      return rows.map(CommunityApi.toPost).toList();
    } catch (e) {
      print('error getting posts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getUserPosts() async {
    try {
      final rows = await CommunityApi.get('/api/posts', {'mine': '1'}) as List;
      return rows.map(CommunityApi.toPost).toList();
    } catch (e) {
      print('error getting your posts: $e');
      return [];
    }
  }

  Future<void> togglePostLike(String postId) => CommunityApi.post('/api/posts/$postId/like');

  // Only shares are counted on the server; likes and comments are counted from their own rows.
  Future<void> updateInteraction(String postId, String field) async {
    if (field == 'shares') await CommunityApi.post('/api/posts/$postId/share');
  }

  Future<String> addPost(String content, String title) async {
    final result = await CommunityApi.post('/api/posts', {'title': title, 'content': content});
    return result['id'] as String;
  }

  Future<void> deletePost(String postId) => CommunityApi.post('/api/posts/$postId/delete');
}
