import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/community_screen.dart';
import 'screens/home_screen.dart';
import 'screens/product_detail_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/search_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print("Loading .env file...");
    await dotenv.load(fileName: '.env', isOptional: true);
    print(".env file loaded successfully");
  } catch (e) {
    print("Error loading .env file: ${e}");
  }

  try {
    print("Starting Firebase initialization...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Initialization failed: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) => _DeviceFrame(child: child!),
      home: AuthScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/auth': (context) => AuthScreen(),
        '/community': (context) => CommunityScreen(),
        '/home': (context) => HomeScreen(),
        '/product-detail': (context) => ProductDetailScreen(upc: 'example'),
        '/profile': (context) => ProfileScreen(),
        '/scanner': (context) => ScannerScreen(),
        '/search': (context) => SearchScreen(),
      },
    );
  }
}

// On wide (desktop) browsers, render the app inside a phone-sized viewport
// so the mobile layouts aren't stretched across the whole window.
class _DeviceFrame extends StatefulWidget {
  const _DeviceFrame({required this.child});

  final Widget child;

  @override
  State<_DeviceFrame> createState() => _DeviceFrameState();
}

class _DeviceFrameState extends State<_DeviceFrame> {
  static const Map<String, Size> _devices = {
    'Small phone': Size(375, 667),
    'Medium phone': Size(393, 852),
    'Large phone': Size(430, 932),
    'Tablet': Size(820, 1180),
  };

  String _device = 'Large phone';
  bool _landscape = false;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screen = mediaQuery.size;

    if (screen.width <= _devices['Large phone']!.width + 250) {
      return widget.child;
    }

    final portrait = _devices[_device]!;
    final target = _landscape ? portrait.flipped : portrait;

    // The app always lays out at the real device size; the whole frame is
    // scaled down when the browser window is too small to show it 1:1.
    // The device choices sit in a column to the right of the frame rather
    // than above it, so the frame gets the window's full height.
    const sideWidth = 170.0;
    final scale = math.min(
      1.0,
      math.min((screen.width - 48 - sideWidth) / target.width,
          (screen.height - 32) / target.height),
    );

    return ColoredBox(
      color: const Color(0xFF2B2B2B),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: target.width * scale,
              height: target.height * scale,
              child: FittedBox(
                child: Container(
                  width: target.width,
                  height: target.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(color: Colors.black54, blurRadius: 30),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      size: target,
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: sideWidth,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final name in _devices.keys)
                      TextButton(
                        onPressed: () => setState(() => _device = name),
                        style: TextButton.styleFrom(
                          foregroundColor: name == _device
                              ? const Color(0xFFFF4D5E)
                              : Colors.white70,
                        ),
                        child: Text(name),
                      ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _landscape = !_landscape),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        iconColor: Colors.white70,
                      ),
                      icon: const Icon(Icons.screen_rotation),
                      label: Text(_landscape ? 'Portrait' : 'Landscape'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
