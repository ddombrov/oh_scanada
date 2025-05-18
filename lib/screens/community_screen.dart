import 'package:flutter/material.dart';
import '../widgets/screen_layout.dart';
import '../widgets/page_title.dart';
import '../widgets/community/community_header.dart';
import '../widgets/community/post_list.dart';
import '../widgets/rewards_widgets.dart';
import '../widgets/community/post_creation_dialog.dart';
import '../colours/colour_system.dart';
import '../services/post_service.dart';
import '../services/rewards_service.dart';
import '../utils/firestore_debug.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showYourFeed = true;
  final PostService _postService = PostService();
  final RewardsService _rewardsService = RewardsService();
  final _themeProvider = ThemeProvider();

  // posts
  List<Map<String, dynamic>> _allPosts = [];
  List<Map<String, dynamic>> _userPosts = [];
  bool _loading = true;

  // search
  String _searchQuery = '';

  // rewards
  int _currentPoints = 0;
  String _currentBadge = 'New User';
  int _nextRewardLevel = 10;
  String _nextBadge = 'Digital Maple Leaf Sticker';

  // debug
  final int testMode = 0; // set to 1 for testing

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(_themeListener);
    _postService.printCurrentUser();
    _fetchRewardsInfo();
    _loadPosts();

    // listen for search changes
    _searchController.addListener(_handleSearch);

    // debug mode
    if (testMode == 1) {
      try {
        FirestoreDebugHelper.debugFirestoreConnection().then((_) {
          _loadPosts();
        });
      } catch (e) {
        print("debug helper failed: $e");
        _loadPosts();
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearch);
    _searchController.dispose();
    _themeProvider.removeListener(_themeListener);
    super.dispose();
  }

  // update search state
  void _handleSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  // get posts that match search
  List<Map<String, dynamic>> _getFilteredPosts(
      List<Map<String, dynamic>> posts) {
    if (_searchQuery.isEmpty) {
      return posts;
    }

    final query = _searchQuery.toLowerCase();
    return posts.where((post) {
      final title = (post['title'] ?? '').toString().toLowerCase();
      final content = (post['content'] ?? '').toString().toLowerCase();

      // check both title and body
      return title.contains(query) || content.contains(query);
    }).toList();
  }

  void _themeListener() {
    if (mounted) {
      setState(() {});
    }
  }

  // theme
  bool get _isDarkMode => _themeProvider.isDarkMode;
  Color get _bgColor =>
      _isDarkMode ? const Color(0xFF121212) : CanadianTheme.offWhite;
  Color get _cardColor => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textColor => _isDarkMode ? Colors.white : CanadianTheme.darkGrey;
  Color get _secondaryTextColor =>
      _isDarkMode ? Colors.white70 : CanadianTheme.darkGrey.withOpacity(0.7);

  // update post likes immediately
  void _updatePost(String postId, Map<String, dynamic> updatedPost) {
    setState(() {
      // find in community posts
      if (_allPosts.any((p) => p['id'] == postId)) {
        final index = _allPosts.indexWhere((p) => p['id'] == postId);
        _allPosts[index] = updatedPost;
      }

      // find in user posts
      if (_userPosts.any((p) => p['id'] == postId)) {
        final index = _userPosts.indexWhere((p) => p['id'] == postId);
        _userPosts[index] = updatedPost;
      }
    });
  }

  // load rewards
  Future<void> _fetchRewardsInfo() async {
    try {
      final rewardInfo = await _rewardsService.getCurrentUserRewardInfo();

      if (rewardInfo != null) {
        setState(() {
          _currentPoints = rewardInfo['currentPoints'] ?? 0;
          _currentBadge = rewardInfo['currentReward']?['reward'] ?? 'New User';

          if (rewardInfo['nextReward'] != null) {
            _nextRewardLevel = rewardInfo['nextReward']['points'];
            _nextBadge = rewardInfo['nextReward']['reward'];
          } else {
            _nextRewardLevel = 100000; // max
            _nextBadge = 'Ultimate Canadian Explorer';
          }
        });
      }
    } catch (e) {
      print('error getting rewards: $e');
    }
  }

  // load posts
  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
    });

    try {
      // all posts
      final allPosts = await _postService.getAllPosts();
      print("loaded ${allPosts.length} posts");

      // user's posts
      final userPosts = await _postService.getUserPosts();
      print("loaded ${userPosts.length} user posts");

      if (mounted) {
        setState(() {
          _allPosts = allPosts;
          _userPosts = userPosts;
          _loading = false;
        });
      }
    } catch (e) {
      print("error loading posts: $e");
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _toggleFeed() {
    setState(() {
      _showYourFeed = !_showYourFeed;
    });
  }

  void _createNewPost() {
    showCreatePostDialog(
      context: context,
      isDarkMode: _isDarkMode,
      textColor: _textColor,
      postService: _postService,
      onPostCreated: _loadPosts,
    );
  }

  @override
  Widget build(BuildContext context) {
    // filter based on search
    final filteredAllPosts = _getFilteredPosts(_allPosts);
    final filteredUserPosts = _getFilteredPosts(_userPosts);

    // check if search has results
    final bool noResults = _searchQuery.isNotEmpty &&
        (_showYourFeed
            ? filteredAllPosts.isEmpty && !_loading
            : filteredUserPosts.isEmpty && !_loading);

    return ScreenLayout(
      body: Container(
        color: _bgColor,
        child: Column(
          children: [
            buildTitle("Community"),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadPosts();
                  await _fetchRewardsInfo();
                },
                child: CustomScrollView(
                  slivers: [
                    // header with search
                    SliverToBoxAdapter(
                      child: buildCommunityHeader(
                        context: context,
                        searchController: _searchController,
                        showYourFeed: _showYourFeed,
                        isDarkMode: _isDarkMode,
                        textColor: _textColor,
                        onToggleFeed: _toggleFeed,
                        onCreatePost: _createNewPost,
                      ),
                    ),

                    // search status
                    if (_searchQuery.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: noResults
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32.0),
                                    child: Text(
                                      'no posts found for "$_searchQuery"',
                                      style: TextStyle(
                                        color: _textColor.withOpacity(0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 8.0, top: 4.0),
                                  child: Text(
                                    'results for: "$_searchQuery"',
                                    style: TextStyle(
                                      color: _textColor.withOpacity(0.7),
                                      fontStyle: FontStyle.italic,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      ),

                    // posts list
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: !noResults
                            ? (_showYourFeed
                                ? buildPostsSection(
                                    posts: filteredAllPosts,
                                    isLoading: _loading,
                                    isUserPosts: false,
                                    icon: Icons.public,
                                    title: "Community Posts",
                                    cardColor: _cardColor,
                                    textColor: _textColor,
                                    secondaryTextColor: _secondaryTextColor,
                                    postService: _postService,
                                    refreshPosts: _loadPosts,
                                    updatePost: _updatePost,
                                  )
                                : buildPostsSection(
                                    posts: filteredUserPosts,
                                    isLoading: _loading,
                                    isUserPosts: true,
                                    icon: Icons.person,
                                    title: "Your Posts",
                                    cardColor: _cardColor,
                                    textColor: _textColor,
                                    secondaryTextColor: _secondaryTextColor,
                                    postService: _postService,
                                    refreshPosts: _loadPosts,
                                    updatePost: _updatePost,
                                  ))
                            : SizedBox.shrink(),
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 200)),
                  ],
                ),
              ),
            ),

            // rewards bar
            buildRewardsSection(
              currentPoints: _currentPoints,
              nextRewardLevel: _nextRewardLevel,
              currentBadge: _currentBadge,
              nextBadge: _nextBadge,
              isDarkMode: _isDarkMode,
              textColor: _textColor,
              secondaryTextColor: _secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
