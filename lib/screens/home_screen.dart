import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/screen_layout.dart';
import '../widgets/page_section.dart';
import '../widgets/page_title.dart';
import '../widgets/progress_bar.dart';
import '../colours/colour_system.dart';
import '../services/post_service.dart';
import '../services/rewards_service.dart';
import '../screens/post_screen.dart';
import '../utils/helpers.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService _postService = PostService();
  final RewardsService _rewardsService = RewardsService();
  final _themeProvider = ThemeProvider();

  List<Map<String, dynamic>> _trendingPosts = [];
  bool _loading = true;

  // Rewards variables
  int _currentPoints = 0;
  String _currentBadge = 'New User';
  int _nextRewardLevel = 10;
  String _nextBadge = 'Digital Maple Leaf Sticker';
  String _nextRewardDescription = '';

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_themeListener);
    _fetchData();
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_themeListener);
    super.dispose();
  }

  void _themeListener() {
    if (mounted) {
      setState(() {});
    }
  }

  // Determine current theme
  bool get _isDarkMode => _themeProvider.isDarkMode;

  Future<void> _fetchData() async {
    try {
      setState(() {
        _loading = true;
      });

      // Fetch rewards information
      final rewardInfo = await _rewardsService.getCurrentUserRewardInfo();

      if (rewardInfo != null) {
        setState(() {
          _currentPoints = rewardInfo['currentPoints'] ?? 0;

          // Set current badge (or default to 'New User')
          _currentBadge = rewardInfo['currentReward']?['reward'] ?? 'New User';

          // Set next reward details
          if (rewardInfo['nextReward'] != null) {
            _nextRewardLevel = rewardInfo['nextReward']['points'];
            _nextBadge = rewardInfo['nextReward']['reward'];
            _nextRewardDescription =
                rewardInfo['nextReward']['description'] ?? '';
          } else {
            // If no next reward, use a default or highest available
            _nextRewardLevel = 100000; // Maximum points
            _nextBadge = 'Ultimate Canadian Explorer';
            _nextRewardDescription = '';
          }
        });
      }

      // Fetch posts
      final posts = await _postService.getAllPosts();

      // Sort posts by likes (trending)
      posts.sort((a, b) => (b['likes'] ?? 0).compareTo(a['likes'] ?? 0));

      // Take top 2 posts
      final List<Map<String, dynamic>> enrichedPosts = [];
      for (var post in posts.take(2)) {
        // Fetch user details for the post
        if (post['post_owner'] is DocumentReference) {
          final userData =
              await _postService.getUserFromReference(post['post_owner']);

          // Create a new map with additional user info
          final enrichedPost = Map<String, dynamic>.from(post);
          enrichedPost['username'] =
              userData?['name'] ?? userData?['username'] ?? 'Unknown User';

          enrichedPosts.add(enrichedPost);
        }
      }

      if (mounted) {
        setState(() {
          _trendingPosts = enrichedPosts;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on theme
    final bgColor =
        _isDarkMode ? const Color(0xFF121212) : CanadianTheme.offWhite;
    final textColor = _isDarkMode ? Colors.white : CanadianTheme.darkGrey;
    final secondaryTextColor = _isDarkMode
        ? Colors.white70
        : CanadianTheme.darkGrey.withValues(alpha: 0.7);

    return ScreenLayout(
      body: Container(
        color: bgColor,
        child: Column(
          children: [
            buildTitle("Home"),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Recent Scans Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: buildSection(
                          title: "Recent Scans",
                          icon: Icons.qr_code_scanner,
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                leading: Image.network(
                                    'https://nwknitwear.com/cdn/shop/products/Hutchinson_sOrganicMapleSyrup_250ml_-MapleLeafbottle_534x700.png?v=1619637206',
                                    width: 40,
                                    height: 40),
                                title: Text("Maple Syrup - Grade A",
                                    style: CanadianTheme.canadianText(
                                      fontSize: 12,
                                      color: textColor,
                                    )),
                                subtitle: Text("Scanned on: March 20, 2025",
                                    style: CanadianTheme.canadianText(
                                      fontSize: 10,
                                      color: secondaryTextColor,
                                    )),
                              ),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                leading: Image.network(
                                    'https://assets.shop.loblaws.ca/products/20134710/b2/en/front/20134710_front_a06_@2.png',
                                    width: 40,
                                    height: 40),
                                title: Text("Canadian Cheddar Cheese",
                                    style: CanadianTheme.canadianText(
                                      fontSize: 12,
                                      color: textColor,
                                    )),
                                subtitle: Text("Scanned on: March 18, 2025",
                                    style: CanadianTheme.canadianText(
                                      fontSize: 10,
                                      color: secondaryTextColor,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Rewards Section (more compact version)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: buildSection(
                          title: "Your Rewards",
                          icon: Icons.card_giftcard,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              buildProgressBar(
                                  _currentPoints, _nextRewardLevel),
                              const SizedBox(height: 4.0),
                              Text(
                                'Current: $_currentBadge',
                                style: CanadianTheme.canadianText(
                                  fontSize: 12,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'Next: $_nextBadge',
                                style: CanadianTheme.canadianText(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                ),
                              ),
                              if (_nextRewardDescription.isNotEmpty)
                                Text(
                                  _nextRewardDescription,
                                  style: CanadianTheme.canadianText(
                                    fontSize: 10,
                                    color: secondaryTextColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Trending Community Posts (more compact)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: buildSection(
                          title: "Trending Community Posts",
                          icon: Icons.trending_up,
                          child: _loading
                              ? const Center(child: CircularProgressIndicator())
                              : _trendingPosts.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No trending posts',
                                        style: CanadianTheme.canadianText(
                                          fontSize: 12,
                                          color: textColor,
                                        ),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: _trendingPosts.map((post) {
                                        // Handle timestamp
                                        DateTime? timestamp;
                                        if (post['createdAt'] is Timestamp) {
                                          timestamp =
                                              (post['createdAt'] as Timestamp)
                                                  .toDate();
                                        }
                                        final timeAgo = timestamp != null
                                            ? Helpers.formatRelativeTime(
                                                timestamp)
                                            : 'Recently';

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // User info
                                            InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PostScreen(post: post),
                                                  ),
                                                );
                                              },
                                              child: Row(
                                                children: [
                                                  // Avatar
                                                  CircleAvatar(
                                                    radius: 14,
                                                    backgroundColor:
                                                        CanadianTheme
                                                            .canadianRed
                                                            .withAlpha(51),
                                                    child: Text(
                                                      post['username']
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: CanadianTheme
                                                          .canadianText(
                                                        color: CanadianTheme
                                                            .canadianRed,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6.0),

                                                  // Username and timestamp
                                                  Expanded(
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          post['username'],
                                                          style: CanadianTheme
                                                              .canadianText(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: textColor,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4.0),
                                                        Text(
                                                          "•",
                                                          style: CanadianTheme
                                                              .canadianText(
                                                                  fontSize: 12,
                                                                  color:
                                                                      textColor),
                                                        ),
                                                        const SizedBox(
                                                            width: 4.0),
                                                        Text(
                                                          timeAgo,
                                                          style: CanadianTheme
                                                              .canadianText(
                                                            fontSize: 10,
                                                            color:
                                                                secondaryTextColor,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4.0),

                                            // Post content
                                            InkWell(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        PostScreen(post: post),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                post['content']?.toString() ??
                                                    '',
                                                style:
                                                    CanadianTheme.canadianText(
                                                  fontSize: 12,
                                                  height: 1.3,
                                                  color: textColor,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(height: 8.0),

                                            // Interaction buttons
                                            Row(
                                              children: [
                                                _buildInteractionButton(
                                                  Icons.thumb_up_outlined,
                                                  'Like',
                                                  post['likes'] ?? 0,
                                                  textColor,
                                                  secondaryTextColor,
                                                ),
                                                const SizedBox(width: 12.0),
                                                _buildInteractionButton(
                                                  Icons.comment_outlined,
                                                  'Comment',
                                                  post['comments'] ?? 0,
                                                  textColor,
                                                  secondaryTextColor,
                                                ),
                                                const SizedBox(width: 12.0),
                                                _buildInteractionButton(
                                                  Icons.share_outlined,
                                                  'Share',
                                                  post['shares'] ?? 0,
                                                  textColor,
                                                  secondaryTextColor,
                                                ),
                                              ],
                                            ),

                                            // Divider
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Divider(
                                                  height: 1.0,
                                                  color: _isDarkMode
                                                      ? Colors.white12
                                                      : CanadianTheme
                                                          .lightGrey),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                        ),
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

  // Interaction button helper method
  Widget _buildInteractionButton(IconData icon, String label, dynamic count,
      Color textColor, Color secondaryTextColor) {
    // Ensure count is an integer
    int countInt = 0;
    if (count is int) {
      countInt = count;
    } else if (count is String) {
      countInt = int.tryParse(count) ?? 0;
    } else if (count is double) {
      countInt = count.toInt();
    }

    return InkWell(
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: secondaryTextColor,
          ),
          const SizedBox(width: 4.0),
          Text(
            '$countInt',
            style: CanadianTheme.canadianText(
              fontSize: 10,
              color: secondaryTextColor,
            ),
          ),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: CanadianTheme.canadianText(
              fontSize: 10,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
