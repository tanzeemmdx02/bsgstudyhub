import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const BsgdBootstrapApp());
}

/// Initializes Firebase before showing the main application.
class BsgdBootstrapApp extends StatefulWidget {
  const BsgdBootstrapApp({super.key});

  @override
  State<BsgdBootstrapApp> createState() => _BsgdBootstrapAppState();
}

class _BsgdBootstrapAppState extends State<BsgdBootstrapApp> {
  late Future<FirebaseApp> _firebaseInitialization;

  @override
  void initState() {
    super.initState();
    _firebaseInitialization = _initializeFirebase();
  }

  Future<FirebaseApp> _initializeFirebase() {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _retryInitialization() {
    setState(() {
      _firebaseInitialization = _initializeFirebase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _firebaseInitialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BootstrapScreen(
            title: 'BSGD Academy',
            message: 'Connecting to Firebase...',
            showLoader: true,
          );
        }

        if (snapshot.hasError) {
          return _FirebaseErrorApp(
            error: snapshot.error,
            onRetry: _retryInitialization,
          );
        }

        return const BsgdOnlineAcademyApp();
      },
    );
  }
}

/// Main application with theme state and Material 3 configuration.
class BsgdOnlineAcademyApp extends StatefulWidget {
  const BsgdOnlineAcademyApp({super.key});

  @override
  State<BsgdOnlineAcademyApp> createState() => _BsgdOnlineAcademyAppState();
}

class _BsgdOnlineAcademyAppState extends State<BsgdOnlineAcademyApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      isDarkMode: _isDarkMode,
      toggleTheme: toggleTheme,
      child: MaterialApp(
        title: 'BSGD Online Academy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: const AuthGate(),
      ),
    );
  }
}

/// Observes Firebase Authentication and selects the initial screen.
///
/// Signed-out users see the public homepage.
/// Signed-in users temporarily see a placeholder until role-based
/// student and teacher routing is connected.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BootstrapScreen(
            title: 'BSGD Academy',
            message: 'Checking your session...',
            showLoader: true,
          );
        }

        if (snapshot.hasError) {
          return _InlineErrorScreen(
            message: 'Unable to check your login session.',
            onRetry: () {
              // The auth stream will continue to emit updates.
              // Restarting the app is not required for normal sign-in.
            },
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const HomeScreen();
        }

        return const HomeScreen();
      },
    );
  }
}

/// Temporary signed-in screen.
///
/// Replace this with Firestore role lookup and the correct
/// student or teacher dashboard in the next integration step.
class SignedInPlaceholder extends StatelessWidget {
  final User user;

  const SignedInPlaceholder({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unable to sign out.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BSGD Academy'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: AppStateScope.of(context).toggleTheme,
            icon: Icon(
              AppStateScope.of(context).isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 64,
                  color: AppTheme.royalBlue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'You are signed in',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? 'Authenticated user',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Your student or teacher dashboard will appear '
                  'after your account role is loaded.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reusable startup loading screen.
class _BootstrapScreen extends StatelessWidget {
  final String title;
  final String message;
  final bool showLoader;

  const _BootstrapScreen({
    required this.title,
    required this.message,
    required this.showLoader,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 64,
                color: AppTheme.royalBlue,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (showLoader) const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }
}

/// Firebase initialization failure screen.
class _FirebaseErrorApp extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;

  const _FirebaseErrorApp({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BSGD Academy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 64,
                    color: AppTheme.accentRose,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase connection failed',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Check your Firebase configuration and internet '
                    'connection, then try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    error?.toString() ?? 'Unknown initialization error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple error display for authentication stream failures.
class _InlineErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InlineErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppTheme.accentRose,
              ),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
  }
}

/// App-wide state available to descendant widgets.
class AppStateScope extends InheritedWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const AppStateScope({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    required super.child,
  });

  static AppStateScope of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppStateScope>();

    assert(result != null, 'No AppStateScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppStateScope oldWidget) {
    return isDarkMode != oldWidget.isDarkMode;
  }
}
