import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:super_selectos/screens/homePage/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2E6C37); // Verde Súper Selectos

    final m3eData = M3EThemeData(
      colorScheme: M3EColorScheme.fromSeed(
        seedColor,
        brightness: Brightness.light,
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        home: const MyHomePage(),
      ),
    );
  }
}
