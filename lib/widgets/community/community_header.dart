import 'package:flutter/material.dart';
import '../search_bar.dart';
import '../../colours/colour_system.dart';

// main header widget
Widget buildCommunityHeader({
  required BuildContext context,
  required TextEditingController searchController,
  required bool showYourFeed,
  required bool isDarkMode,
  required Color textColor,
  required VoidCallback onToggleFeed,
  required VoidCallback onCreatePost,
}) {
  return Column(
    children: [
      // search and create row
      Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
        child: Row(
          children: [
            // search bar takes most of the space
            Expanded(
                child: buildSearchBar(
                    searchController: searchController,
                    hintText: "search posts...")),
            _buildAddButton(onCreatePost),
          ],
        ),
      ),

      // feed toggle tabs
      _buildFeedToggleBar(
        showYourFeed: showYourFeed,
        isDarkMode: isDarkMode,
        onToggleFeed: onToggleFeed,
      ),
    ],
  );
}

// create post button
Widget _buildAddButton(VoidCallback onCreatePost) {
  return Container(
    margin: const EdgeInsets.only(left: 8.0),
    decoration: BoxDecoration(
      color: CanadianTheme.canadianRed,
      borderRadius: BorderRadius.circular(10.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        )
      ],
    ),
    child: IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: onCreatePost,
      tooltip: 'create post',
    ),
  );
}

// feed toggle container
Widget _buildFeedToggleBar({
  required bool showYourFeed,
  required bool isDarkMode,
  required VoidCallback onToggleFeed,
}) {
  return Container(
    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16.0),
    child: Row(
      children: [
        _buildTabButton('your feed', showYourFeed, onToggleFeed),
        _buildTabButton('your posts', !showYourFeed, onToggleFeed),
      ],
    ),
  );
}

// tab button
Widget _buildTabButton(String text, bool isActive, VoidCallback onTap) {
  return Expanded(
    child: InkWell(
      onTap: isActive ? null : onTap,
      mouseCursor: SystemMouseCursors.click,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? CanadianTheme.canadianRed : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: CanadianTheme.canadianText(
              color: isActive
                  ? CanadianTheme.canadianRed
                  : CanadianTheme.darkGrey.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ),
  );
}
