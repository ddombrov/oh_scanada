import 'package:flutter/material.dart';
import '../colours/colour_system.dart';

class NavBar extends StatelessWidget {
  
  final Function(int) onTabSelected;
  final int currentIndex;
  final bool isDarkMode;

  const NavBar({
    super.key,
    required this.onTabSelected,
    required this.currentIndex,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : CanadianTheme.darkGrey,
      selectedItemColor: CanadianTheme.canadianRed,
      unselectedItemColor: CanadianTheme.offWhite,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera),
          label: 'Scanner',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Community',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
