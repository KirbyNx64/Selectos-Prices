import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/screens/homePage/home_page.dart';
import 'package:super_selectos/services/android_platform_version.dart';
import 'package:super_selectos/services/app_theme_controller.dart';
import 'package:super_selectos/services/favorites_repository.dart';
import 'package:super_selectos/services/shopping_cart_repository.dart';
import 'package:super_selectos/services/store_selection_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await AndroidPlatformVersion.initialize();
  await Future.wait([
    ShoppingCartRepository.instance.initialize(),
    FavoritesRepository.instance.initialize(),
    AppThemeController.instance.initialize(),
    StoreSelectionController.instance.initialize(),
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2E6C37); // Verde Súper Selectos
    final themeController = AppThemeController.instance;

    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final brightness = themeController.isDarkMode
            ? Brightness.dark
            : Brightness.light;
        final m3eData = M3EThemeData(
          colorScheme: M3EColorScheme.fromSeed(
            seedColor,
            brightness: brightness,
          ),
          navigationBarTheme: M3ENavigationBarTheme.defaults.copyWith(
            indicatorScaleSpring: M3EMotion.expressiveSpatialDefault,
            activeLabelWeight: FontWeight.w700,
            inactiveLabelWeight: FontWeight.w500,
          ),
        );

        return M3ETheme(
          data: m3eData,
          child: MaterialApp(
            title: 'Selectos Prices',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('es', 'SV'),
              Locale('es', ''),
              Locale('en', ''),
            ],
            locale: const Locale('es', 'SV'),
            theme: _buildTheme(seedColor, Brightness.light),
            darkTheme: _buildTheme(seedColor, Brightness.dark),
            themeMode: themeController.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            builder: (context, child) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              final backgroundColor = theme.colorScheme.surface;

              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  statusBarBrightness: isDark
                      ? Brightness.dark
                      : Brightness.light,
                  systemNavigationBarColor: backgroundColor,
                  systemNavigationBarDividerColor: Colors.transparent,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  systemNavigationBarContrastEnforced: false,
                ),
                // Android 16 siempre dibuja la app detrás de la navegación.
                // Este fondo evita que la zona transparente revele el blanco
                // de la ventana y mantiene el mismo color que el Scaffold.
                child: ColoredBox(color: backgroundColor, child: child!),
              );
            },
            home: const MyHomePage(),
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
