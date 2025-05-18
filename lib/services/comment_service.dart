import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/helpers.dart';

class CommentService {

  // check if comment is liked by current user
  Future<bool> isCommentLiked(String commentId) async {
    try {
      DocumentSnapshot userDoc =
          await Helpers.usersCollection.doc(Helpers.currentUserId).get();
      List<dynamic> likedComments = userDoc.get('liked_comments') ?? [];
      return likedComments.contains('/comments/$commentId');
    } catch (e) {
      print('error checking liked comment: $e');
      return false;
    }
  }

  // like/unlike comment
  Future<void> toggleCommentLike(String commentId) async {
    try {
      DocumentReference userRef = Helpers.currentUserRef;
      DocumentReference commentRef = Helpers.commentsCollection.doc(commentId);

      // batch write for atomic ops
      WriteBatch batch = Helpers.firestore.batch();

      // get user doc
      DocumentSnapshot userDoc = await userRef.get();
      List<dynamic> likedComments =
          List.from(userDoc.get('liked_comments') ?? []);

      String commentPath = '/comments/$commentId';

      if (likedComments.contains(commentPath)) {
        // unlike
        likedComments.remove(commentPath);
        batch.update(commentRef, {'likes': FieldValue.increment(-1)});
      } else {
        // like
        likedComments.add(commentPath);
        batch.update(commentRef, {'likes': FieldValue.increment(1)});
      }

      // update user's liked comments array
      batch.update(userRef, {'liked_comments': likedComments});

      await batch.commit();
      print("toggled like for comment $commentId");
    } catch (e) {
      print('error toggling comment like: $e');
      rethrow;
    }
  }

  // get all comments with like status
  Future<List<Map<String, dynamic>>> getAllCommentsWithLikeStatus() async {
    try {
      final QuerySnapshot snapshot = await Helpers.commentsCollection.get();

      return Future.wait(snapshot.docs.map((doc) async {
        Map<String, dynamic> data = Helpers.mapDocWithId(doc);
        data['is_liked'] = await isCommentLiked(doc.id);
        return data;
      }).toList());
    } catch (e) {
      print("error getting comments: $e");
      return [];
    }
  }

  // get all comments
  Future<List<Map<String, dynamic>>> getAllComments() async {
    try {
      final QuerySnapshot snapshot = await Helpers.commentsCollection.get();
      return snapshot.docs.map(Helpers.mapDocWithId).toList();
    } catch (e) {
      print("error getting comments: $e");
      return [];
    }
  }

  // get comments for post with like status
  Future<List<Map<String, dynamic>>> getCommentsForPostWithLikeStatus(
      DocumentReference postRef) async {
    try {
      final QuerySnapshot snapshot = await Helpers.commentsCollection
          .where('parent_post', isEqualTo: postRef)
          .orderBy('createdAt', descending: true)
          .get();

      return Future.wait(snapshot.docs.map((doc) async {
        Map<String, dynamic> data = Helpers.mapDocWithId(doc);
        data['is_liked'] = await isCommentLiked(doc.id);
        return data;
      }).toList());
    } catch (e) {
      print("error getting post comments: $e");
      return [];
    }
  }

  // get comments for a post
  Future<List<Map<String, dynamic>>> getCommentsForPost(
      DocumentReference postRef) async {
    try {
      final QuerySnapshot snapshot = await Helpers.commentsCollection
          .where('parent_post', isEqualTo: postRef)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map(Helpers.mapDocWithId).toList();
    } catch (e) {
      print("error getting post comments: $e");
      return [];
    }
  }

  // get user's comments
  Future<List<Map<String, dynamic>>> getUserComments() async {
    try {
      final QuerySnapshot snapshot = await Helpers.commentsCollection
          .where('comment_owner', isEqualTo: Helpers.currentUserRef)
          .get();

      return snapshot.docs.map(Helpers.mapDocWithId).toList();
    } catch (e) {
      print("error getting user comments: $e");
      return [];
    }
  }

  // comments stream
  Stream<QuerySnapshot> getAllCommentsStream() {
    print("getting comments stream");
    return Helpers.commentsCollection.snapshots();
  }

  // comments stream for post
  Stream<QuerySnapshot> getCommentsForPostStream(DocumentReference postRef) {
    print("getting comments for post: ${postRef.id}");

    return Helpers.commentsCollection
        .where('parent_post', isEqualTo: postRef)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // user comments stream
  Stream<QuerySnapshot> getUserCommentsStream() {
    print("getting user comments for: ${Helpers.currentUserId}");

    return Helpers.commentsCollection
        .where('comment_owner', isEqualTo: Helpers.currentUserRef)
        .snapshots();
  }

  // add new comment
  Future<String> addComment(
      {required String content, required DocumentReference postRef}) async {
    try {
      // create doc ref first to get ID
      DocumentReference docRef = Helpers.commentsCollection.doc();

      await docRef.set({
        'content': content,
        'comment_owner': Helpers.currentUserRef,
        'parent_post': postRef,
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // update post's comment count
      await postRef.update({'comments': FieldValue.increment(1)});

      print("added comment: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print('error adding comment: $e');
      rethrow;
    }
  }

  Future<void> updateCommentLikes(String commentId) async {
    try {
      await Helpers.commentsCollection
          .doc(commentId)
          .update({'likes': FieldValue.increment(1)});
      print("updated likes for comment $commentId");
    } catch (e) {
      print('error updating comment likes: $e');
      rethrow;
    }
  }

  // delete comment
  Future<void> deleteComment(
      String commentId, DocumentReference postRef) async {
    try {
      await Helpers.commentsCollection.doc(commentId).delete();

      // decrement post comment count
      await postRef.update({'comments': FieldValue.increment(-1)});

      print("deleted comment $commentId");
    } catch (e) {
      print('error deleting comment: $e');
      rethrow;
    }
  }
}
