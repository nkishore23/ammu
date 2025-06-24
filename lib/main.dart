import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth/signup_page.dart';
import 'auth/login_page.dart';
import 'dart:async';
import 'package:ammu_app/helper/database_helper.dart';
import 'firebase_options.dart';
import 'screens/bluetooth/add_device_screen.dart';

void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AmmuApp());
}

class AmmuApp extends StatelessWidget {
  const AmmuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMMU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF003366),
        fontFamily: 'Inter',
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/signup': (context) => const SignUpPage(),
        '/login': (context) => const LoginPage(),
        '/bluetooth': (context) => const BluetoothScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Start animations
    _logoController.forward();
    Timer(const Duration(milliseconds: 800), () {
      _textController.forward();
    });

    // Initialize session and navigate
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize user session
    await UserSession().initialize();

    // Wait for splash duration
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Check if user is logged in
      if (UserSession().isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/signup');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF002D62),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Logo
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 60,
                      color: Color(0xFF002D62),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Animated Text
            AnimatedBuilder(
              animation: _textAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _textAnimation.value,
                  child: Column(
                    children: [
                      const Text(
                        'AMMU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Move with Mother Care',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Loading indicator
                      const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// User Session Management
class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  User? _currentUser;
  SharedPreferences? _prefs;

  // Initialize session
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUserSession();
  }

  // Get current user
  User? get currentUser => _currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Save user session
  Future<void> saveUserSession(User user) async {
    _currentUser = user;
    await _prefs?.setInt('user_id', user.id!);
    await _prefs?.setString('user_email', user.email);
    await _prefs?.setString('user_mobile', user.mobileNumber);
    await _prefs?.setBool('is_logged_in', true);
  }

  // Load user session from storage
  Future<void> _loadUserSession() async {
    final isLoggedIn = _prefs?.getBool('is_logged_in') ?? false;

    if (isLoggedIn) {
      final userId = _prefs?.getInt('user_id');
      if (userId != null) {
        _currentUser = await DatabaseHelper().getUserById(userId);
      }
    }
  }

  // Clear user session (logout)
  Future<void> clearSession() async {
    _currentUser = null;
    await _prefs?.clear();
  }

  // Update current user data
  Future<void> updateCurrentUser() async {
    if (_currentUser?.id != null) {
      _currentUser = await DatabaseHelper().getUserById(_currentUser!.id!);
    }
  }
}
