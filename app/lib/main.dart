import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router.dart';
import 'core/services/appwrite_service.dart';

/// Provider pour SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

/// Provider pour le thème de l'application
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

void main() async {
  // S'assurer que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Configurer l'orientation de l'écran
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configurer la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUIOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Initialiser les services
  await _initializeServices();

  // Charger SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Lancer l'application
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const FugApp(),
    ),
  );
}

/// Initialise tous les services nécessaires au démarrage
Future<void> _initializeServices() async {
  // Initialiser Appwrite
  AppwriteService.instance;

  // TODO: Initialiser les notifications locales
  // await _initializeNotifications();

  // TODO: Initialiser la géolocalisation
  // await _initializeLocation();
}

/// Application principale FUG
class FugApp extends ConsumerWidget {
  const FugApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'FUG - Find Urban Gatherings',
      debugShowCheckedModeBanner: false,

      // Configuration du routeur
      routerConfig: router,

      // Theme clair
      theme: _buildLightTheme(),

      // Theme sombre
      darkTheme: _buildDarkTheme(),

      // Mode du theme
      themeMode: themeMode,
    );
  }

  /// Construit le thème clair
  ThemeData _buildLightTheme() {
    const primaryColor = Color(0xFF6750A4); // Material 3 Purple
    const secondaryColor = Color(0xFF625B71);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        secondary: secondaryColor,
      ),
      fontFamily: 'Poppins',

      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Boutons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Construit le thème sombre
  ThemeData _buildDarkTheme() {
    const primaryColor = Color(0xFFD0BCFF); // Material 3 Purple Light
    const secondaryColor = Color(0xFFCCC2DC);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        secondary: secondaryColor,
      ),
      fontFamily: 'Poppins',

      // AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),

      // Cards
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Boutons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Note: AuthWrapper n'est plus necessaire car GoRouter gere la redirection
// basee sur l'etat d'authentification via authStateProvider
