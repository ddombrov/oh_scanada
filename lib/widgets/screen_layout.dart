import 'package:flutter/material.dart';
import 'nav_bar.dart';
import '../colours/colour_system.dart';

class ScreenLayout extends StatefulWidget {
  final Widget body;

  const ScreenLayout({super.key, required this.body});

  @override
  State<ScreenLayout> createState() => _ScreenLayoutState();
}

class _ScreenLayoutState extends State<ScreenLayout> {
  int _currentIndex = 0;
  final _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndexBasedOnRoute();
      _themeProvider.addListener(_themeListener);
    });
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

  void _updateIndexBasedOnRoute() {
    String? currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == null) return;

    int newIndex;
    switch (currentRoute) {
      case '/home':
        newIndex = 0;
        break;
      case '/search':
        newIndex = 1;
        break;
      case '/scanner':
        newIndex = 2;
        break;
      case '/community':
        newIndex = 3;
        break;
      case '/profile':
        newIndex = 4;
        break;
      default:
        newIndex = 0;
    }

    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/search');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/scanner');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/community');
        break;
      case 4:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateIndexBasedOnRoute();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _themeProvider.isDarkMode;

    // Wrap everything in a ColourAdjustment widget
    return ColourAdjustment(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Oh Scanada",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          backgroundColor: CanadianTheme.canadianRed,
          foregroundColor: Colors.white,
        ),
        body: Container(
          color: isDark ? const Color(0xFF121212) : CanadianTheme.offWhite,
          child: widget.body,
        ),
        bottomNavigationBar: NavBar(
          onTabSelected: _onTabSelected,
          currentIndex: _currentIndex,
          isDarkMode: isDark,
        ),
      ),
    );
  }
}
