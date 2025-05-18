import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Helpers {

  // Firebase instances
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firestore getter
  static FirebaseFirestore get firestore => _firestore;

  // Database collections
  static final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');
  static final CollectionReference postsCollection =
      FirebaseFirestore.instance.collection('posts');
  static final CollectionReference commentsCollection =
      FirebaseFirestore.instance.collection('comments');
  static final CollectionReference rewardsCollection =
      FirebaseFirestore.instance.collection('rewards');

  // User id
  static String get currentUserId {
    return _auth.currentUser?.uid ?? 'anonymous_user';
  }

  // User ref
  static DocumentReference get currentUserRef {
    return usersCollection.doc(currentUserId);
  }

  // Add id to doc data
  static Map<String, dynamic> mapDocWithId(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return data;
  }

  // Get user from ref
  static Future<Map<String, dynamic>?> getUserFromReference(
      DocumentReference userRef) async {
    try {
      DocumentSnapshot userDoc = await userRef.get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['uid'] = userDoc.id;
        return userData;
      }
    } catch (e) {
      print('Error getting user from ref: $e');
    }
    return null;
  }

  // Get user by id
  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      DocumentReference userRef;

      // Handle ref or string
      if (userId is DocumentReference) {
        userRef = userId as DocumentReference;
      } else {
        userRef = usersCollection.doc(userId);
      }

      return await getUserFromReference(userRef);
    } catch (e) {
      print('Error getting user $userId: $e');
    }
    return null;
  }

  // Format time as "X time ago"
  static String formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'just now';
    }
  }

  // Debug info
  static void printCurrentUser() {
    final user = _auth.currentUser;
    print("=== Auth Info ===");
    print("User: ${user?.uid ?? 'not signed in'}");
    print("Email: ${user?.email}");
    print("Name: ${user?.displayName}");
    print("================");
  }
}
