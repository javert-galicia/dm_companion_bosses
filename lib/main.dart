import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'screens/monster_detail_screen.dart';

// Definir colores personalizados
const parchmentBackground = Color(0xFFF4E4BC); // Color base pergamino
const parchmentDark = Color(0xFFE4D5B7);       // Pergamino más oscuro
const parchmentBorder = Color(0xFFBE8B42);     // Bordes color marrón
const textColor = Color(0xFF4A3728);           // Texto marrón oscuro

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      title: 'D&D Monster Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red[700] ?? Colors.red),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        cardTheme: CardTheme(
          color: parchmentDark.withOpacity(0.9),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: parchmentBorder,
              width: 1,
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: textColor),
          bodyMedium: TextStyle(color: textColor),
          titleLarge: TextStyle(color: textColor),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: parchmentDark,
          foregroundColor: textColor,
          elevation: 2,
        ),
      ),
      home: const MonsterDetailScreen(),
    );
  }
}
