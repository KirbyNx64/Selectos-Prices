import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/screens/homePage/home_page.dart';
import 'package:super_selectos/services/app_theme_controller.dart';
import 'package:super_selectos/services/shopping_cart_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    ShoppingCartRepository.instance.initialize(),
    AppThemeController.instance.initialize(),
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
            home: const MyHomePage(),
          ),
        );
      },
    );
  }

  ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      appBarTheme: const AppBarTheme(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
