import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RewardsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // db collections
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _rewardsCollection =
      FirebaseFirestore.instance.collection('rewards');

  // current user getter
  String get currentUserId {
    return _auth.currentUser?.uid ?? 'anonymous_user';
  }

  // fetch user rewards data
  Future<Map<String, dynamic>?> getCurrentUserRewardInfo() async {
    try {
      // get user doc
      DocumentSnapshot userDoc =
          await _usersCollection.doc(currentUserId).get();

      if (!userDoc.exists) {
        return null;
      }

      // get points
      int currentPoints = userDoc['reward_progress'] ?? 0;

      // find next available reward
      QuerySnapshot rewardsSnapshot = await _rewardsCollection
          .where('points', isGreaterThan: currentPoints)
          .orderBy('points')
          .limit(1)
          .get();

      // find current reward tier
      QuerySnapshot currentRewardSnapshot = await _rewardsCollection
          .where('points', isLessThanOrEqualTo: currentPoints)
          .orderBy('points', descending: true)
          .limit(1)
          .get();

      Map<String, dynamic>? nextReward;
      Map<String, dynamic>? currentReward;

      if (rewardsSnapshot.docs.isNotEmpty) {
        nextReward = rewardsSnapshot.docs.first.data() as Map<String, dynamic>;
        nextReward['id'] = rewardsSnapshot.docs.first.id;
      }

      if (currentRewardSnapshot.docs.isNotEmpty) {
        currentReward =
            currentRewardSnapshot.docs.first.data() as Map<String, dynamic>;
        currentReward['id'] = currentRewardSnapshot.docs.first.id;
      }

      return {
        'currentPoints': currentPoints,
        'currentReward': currentReward,
        'nextReward': nextReward,
      };
    } catch (e) {
      print('error getting rewards: $e');
      return null;
    }
  }

  // add points to user
  Future<void> updateRewardProgress(int points) async {
    try {
      await _usersCollection
          .doc(currentUserId)
          .update({'reward_progress': FieldValue.increment(points)});
    } catch (e) {
      print('error updating points: $e');
      rethrow;
    }
  }

  // redeem reward
  Future<void> claimReward(String rewardId) async {
    try {
      // check if reward exists
      DocumentSnapshot rewardDoc = await _rewardsCollection.doc(rewardId).get();

      if (!rewardDoc.exists) {
        throw Exception('reward not found');
      }

      Map<String, dynamic> rewardData =
          rewardDoc.data() as Map<String, dynamic>;
      int requiredPoints = rewardData['points'];

      // check if user has enough points
      DocumentSnapshot userDoc =
          await _usersCollection.doc(currentUserId).get();
      int currentPoints = userDoc['reward_progress'] ?? 0;

      if (currentPoints < requiredPoints) {
        throw Exception('not enough points');
      }

      print('claimed ${rewardData['reward']}!');
    } catch (e) {
      print('error claiming reward: $e');
      rethrow;
    }
  }
}
