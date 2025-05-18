import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreDebugHelper {
  static Future<void> debugFirestoreConnection() async {

    try {
      print("=== Firestore Debug ===");

      // Check auth
      final user = FirebaseAuth.instance.currentUser;
      print("Current user: ${user?.uid ?? 'not signed in'}");

      // Firestore instance
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Check users collection
      print("\ncCecking users...");
      try {
        final usersQuery = await firestore.collection('users').limit(5).get();
        print("found ${usersQuery.docs.length} users:");
        for (var doc in usersQuery.docs) {
          print("  - id: ${doc.id}");
          final data = doc.data();
          print("    fields: ${data.keys.join(', ')}");
        }
      } catch (e) {
        print("error accessing users: $e");
      }

      // Check posts collection
      print("\nchecking posts...");
      try {
        final postsQuery = await firestore.collection('posts').limit(10).get();
        print("found ${postsQuery.docs.length} posts:");
        for (var doc in postsQuery.docs) {
          print("  - post: ${doc.id}");
          final data = doc.data();
          print("    fields: ${data.keys.join(', ')}");

          // Check specific fields
          print("    owner: ${data['post_owner']}");
          print(
              "    content: ${data['content']?.toString().substring(0, min(20, (data['content'] ?? '').toString().length))}${data['content']!.toString().length > 20 ? '...' : ''}");

          // Check timestamp
          if (data.containsKey('createdAt')) {
            print(
                "    created: ${data['createdAt']} (${data['createdAt']?.runtimeType})");
          } else {
            print("    created: missing");
          }
        }
      } catch (e) {
        print("error accessing posts: $e");
      }

      // Test user posts query
      if (user != null) {
        print("\ntesting user posts...");
        try {
          final userPostsQuery = await firestore
              .collection('posts')
              .where('post_owner', isEqualTo: user.uid)
              .get();

          print("found ${userPostsQuery.docs.length} user posts:");
          for (var doc in userPostsQuery.docs) {
            print("  - ${doc.id}");
          }
        } catch (e) {
          print("error with user posts: $e");
        }
      }

      // Test ordered posts
      print("\ntesting sorted posts...");
      try {
        final orderedPostsQuery = await firestore
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get();

        print("found ${orderedPostsQuery.docs.length} sorted posts:");
        for (var doc in orderedPostsQuery.docs) {
          final data = doc.data();
          print("  - ${doc.id}, created: ${data['createdAt']}");
        }
      } catch (e) {
        print("error with sorted posts: $e");
      }

      print("=== debug done ===");
    } catch (e) {
      print("=== debug failed ===");
      print("error: $e");
    }
  }

  // Helper for string truncation
  static int min(int a, int b) {
    return a < b ? a : b;
  }
}
