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
    await dotenv.load(fileName: '.env');
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
