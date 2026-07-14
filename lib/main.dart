import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/database_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Try to initialize Firebase. If config files are missing,
  // we catch the error and default to Mock database mode safely.
  bool firebaseInitialized = false;
  try {
    // When using flutterfire configure, this will look for DefaultFirebaseOptions.currentPlatform
    // But since it's not generated yet, standard initializeApp will read google-services / Info.plist.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    debugPrint('Firebase initialization failed (operating in Mock mode): $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // If Firebase failed to initialize, force Mock mode to be true.
        // If it succeeded, we let it default to true but the user can toggle it off.
        if (!firebaseInitialized)
          useMockDatabaseProvider.overrideWith((ref) => UseMockDatabaseNotifier(prefs)..toggle(true)),
      ],
      child: const DentManApp(),
    ),
  );
}

class DentManApp extends ConsumerWidget {
  const DentManApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'DentMan',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: authState.isAuthenticated
          ? const DashboardScreen()
          : const LoginScreen(),
    );
  }
}
