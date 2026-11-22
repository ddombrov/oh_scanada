import 'package:flutter/material.dart';
import '../widgets/screen_layout.dart';
import '../widgets/page_section.dart';
import '../widgets/page_title.dart';
import '../widgets/progress_bar.dart';
import '../colours/colour_system.dart';
import '../services/post_service.dart';
import '../services/rewards_service.dart';
import '../screens/post_screen.dart';
import '../utils/helpers.dart';
import '../utils/account_session.dart';

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

  List<Map<String, String>> get _recentScans {
    switch (AccountSession.mode) {
      case AccountMode.guest:
        return const [];
      case AccountMode.example:
        return ExampleAccount.recentScans;
      case AccountMode.user:
        return ExampleAccount.recentScans.take(2).toList();
    }
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _loading = true;
      });

      // Fetch rewards information
      final Map<String, dynamic>? rewardInfo = AccountSession.isGuest
          ? null
          : AccountSession.isExample
              ? ExampleAccount.rewardInfo
              : await _rewardsService.getCurrentUserRewardInfo();

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
      final enrichedPosts = posts.take(2).toList();

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
                          image: 'lib/assets/icons/barcode.png',
                          child: _recentScans.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'No scans yet',
                                    style: CanadianTheme.canadianText(
                                      fontSize: 12,
                                      color: textColor,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _recentScans.map((scan) {
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8.0, vertical: 4.0),
                                      leading: scan['image'] != null
                                          ? Image.network(scan['image']!,
                                              width: 40, height: 40)
                                          : const SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: Icon(
                                                  Icons.shopping_basket,
                                                  color: CanadianTheme
                                                      .canadianRed),
                                            ),
                                      title: Text(scan['name']!,
                                          style: CanadianTheme.canadianText(
                                            fontSize: 12,
                                            color: textColor,
                                          )),
                                      subtitle: Text(
                                          "Scanned on: ${scan['date']}",
                                          style: CanadianTheme.canadianText(
                                            fontSize: 10,
                                            color: secondaryTextColor,
                                          )),
                                    );
                                  }).toList(),
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
                          image: 'lib/assets/icons/maple-syrup.png',
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
                          image: 'lib/assets/icons/goose.png',
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
                                        final DateTime? timestamp =
                                            post['createdAt'] is DateTime
                                                ? post['createdAt'] as DateTime
                                                : null;
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
