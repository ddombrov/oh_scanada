import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // collections
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _postsCollection =
      FirebaseFirestore.instance.collection('posts');

  // user id getter
  String get currentUserId {
    return _auth.currentUser?.uid ?? 'anonymous_user';
  }

  // check if user liked a post
  Future<bool> isPostLiked(String postId) async {
    try {
      DocumentSnapshot userDoc =
          await _usersCollection.doc(currentUserId).get();
      List<dynamic> likedPosts = userDoc.get('liked_posts') ?? [];
      return likedPosts.contains('/posts/$postId');
    } catch (e) {
      print('error checking liked post: $e');
      return false;
    }
  }

  // toggle post like status
  Future<void> togglePostLike(String postId) async {
    try {
      DocumentReference userRef = _usersCollection.doc(currentUserId);
      DocumentReference postRef = _postsCollection.doc(postId);

      // batch for atomic operations
      WriteBatch batch = _firestore.batch();

      // get user data
      DocumentSnapshot userDoc = await userRef.get();
      List<dynamic> likedPosts = List.from(userDoc.get('liked_posts') ?? []);

      String postPath = '/posts/$postId';

      if (likedPosts.contains(postPath)) {
        // unlike
        likedPosts.remove(postPath);
        batch.update(postRef, {'likes': FieldValue.increment(-1)});
      } else {
        // like
        likedPosts.add(postPath);
        batch.update(postRef, {'likes': FieldValue.increment(1)});
      }

      // update user doc
      batch.update(userRef, {'liked_posts': likedPosts});

      await batch.commit();
      print("toggled like for post $postId");
    } catch (e) {
      print('error toggling like: $e');
      rethrow;
    }
  }

  // get all posts
  Future<List<Map<String, dynamic>>> getAllPosts() async {
    try {
      final QuerySnapshot snapshot = await _postsCollection.get();

      return Future.wait(snapshot.docs.map((doc) async {
        // add id to data
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // check like status
        data['is_liked'] = await isPostLiked(doc.id);

        return data;
      }).toList());
    } catch (e) {
      print("error getting posts: $e");
      return [];
    }
  }

  // get user's posts
  Future<List<Map<String, dynamic>>> getUserPosts() async {
    try {
      // get user ref
      DocumentReference currentUserRef = _usersCollection.doc(currentUserId);

      // query with ref
      final QuerySnapshot snapshot = await _postsCollection
          .where('post_owner', isEqualTo: currentUserRef)
          .get();

      return Future.wait(snapshot.docs.map((doc) async {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        // check like status
        data['is_liked'] = await isPostLiked(doc.id);

        return data;
      }).toList());
    } catch (e) {
      print("error getting user posts: $e");
      return [];
    }
  }

  // posts stream
  Stream<QuerySnapshot> getAllPostsStream() {
    print("getting posts stream");
    return _postsCollection.snapshots();
  }

  // user posts stream
  Stream<QuerySnapshot> getUserPostsStream() {
    print("getting posts for user: $currentUserId");

    DocumentReference userRef = _usersCollection.doc(currentUserId);

    return _postsCollection.where('post_owner', isEqualTo: userRef).snapshots();
  }

  // get user by id
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      DocumentReference userRef;

      // handle userId as ref or string
      if (userId is DocumentReference) {
        userRef = userId as DocumentReference;
      } else {
        userRef = _usersCollection.doc(userId);
      }

      DocumentSnapshot userDoc = await userRef.get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['uid'] = userDoc.id;
        return userData;
      }
    } catch (e) {
      print('error getting user $userId: $e');
    }
    return null;
  }

  // get user from reference
  Future<Map<String, dynamic>?> getUserFromReference(
      DocumentReference userRef) async {
    try {
      DocumentSnapshot userDoc = await userRef.get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['uid'] = userDoc.id;
        return userData;
      }
    } catch (e) {
      print('error getting user from ref: $e');
    }
    return null;
  }

  // create new post
  Future<String> addPost(String content, String title) async {
    try {
      // user ref
      DocumentReference userRef = _usersCollection.doc(currentUserId);

      // create doc ref to get ID
      DocumentReference docRef = _postsCollection.doc();

      // add post data
      await docRef.set({
        'comments': 0,
        'content': content,
        'likes': 0,
        'post_owner': userRef, 
        'shares': 0,
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("created post: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print('error creating post: $e');
      rethrow;
    }
  }

  // update post interaction count
  Future<void> updateInteraction(String postId, String field) async {
    try {
      await _postsCollection
          .doc(postId)
          .update({field: FieldValue.increment(1)});
      print("updated $field count for post $postId");
    } catch (e) {
      print('error updating post: $e');
      rethrow;
    }
  }

  // delete post
  Future<void> deletePost(String postId) async {
    try {
      await _postsCollection.doc(postId).delete();
      print("deleted post $postId");
    } catch (e) {
      print('error deleting post: $e');
      rethrow;
    }
  }

  // debug info
  void printCurrentUser() {
    final user = _auth.currentUser;
    print("=== auth user ===");
    print("user: ${user?.uid ?? 'not signed in'}");
    print("email: ${user?.email}");
    print("name: ${user?.displayName}");
    print("===============");
  }
}
