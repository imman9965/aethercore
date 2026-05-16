import 'package:flutter/material.dart';

import '../di/injector.dart';
import 'auth_gate.dart';

/// Root MaterialApp. Theme lives here; everything else is composed by
/// the [Injector].
///
/// Design language: glacial blue + crisp white. A deep navy-to-indigo
/// gradient powers the hero surfaces (boss timer, primary CTAs); pure
/// white cards float on a faint blue-tinted background; a single cyan
/// accent reserved for "live / pulsing" elements.
class AetherApp extends StatelessWidget {
  const AetherApp({super.key, required this.injector});

  final Injector injector;

  // -- Design tokens --------------------------------------------------------
  static const Color kPrimary = Color(0xFF1565C0);       // Cobalt
  static const Color kPrimaryDark = Color(0xFF0B3D91);   // Midnight cobalt
  static const Color kPrimaryLight = Color(0xFF5B8DEF);  // Soft cobalt
  static const Color kAccentCyan = Color(0xFF00E5FF);    // Live-pulse glow
  static const Color kSurface = Color(0xFFFFFFFF);
  static const Color kSurfaceSubtle = Color(0xFFF4F8FD);
  static const Color kSurfaceContainer = Color(0xFFE8F1FB);
  static const Color kOnSurface = Color(0xFF0F1F3D);
  static const Color kOnSurfaceMuted = Color(0xFF5A6A85);
  static const Color kOutline = Color(0xFFD6E2F0);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = const ColorScheme.light(
      primary: kPrimary,
      onPrimary: Colors.white,
      primaryContainer: kSurfaceContainer,
      onPrimaryContainer: kPrimaryDark,
      secondary: kPrimaryLight,
      onSecondary: Colors.white,
      tertiary: kAccentCyan,
      onTertiary: kPrimaryDark,
      surface: kSurface,
      onSurface: kOnSurface,
      surfaceContainerHighest: kSurfaceContainer,
      onSurfaceVariant: kOnSurfaceMuted,
      outline: kOutline,
      outlineVariant: kOutline,
      error: Color(0xFFC62828),
      onError: Colors.white,
    );

    return SafeArea(
      top:false,
      bottom: true,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AetherCore',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: kSurfaceSubtle,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            foregroundColor: kOnSurface,
            titleTextStyle: TextStyle(
              color: kOnSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          cardTheme: CardThemeData(
            color: kSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: kOutline),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: kOutline,
              disabledForegroundColor: kOnSurfaceMuted,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: kSurface,
            hintStyle: const TextStyle(color: kOnSurfaceMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kOutline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kOutline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kPrimary, width: 1.6),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: kOutline,
            thickness: 1,
            space: 1,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: kOnSurface),
            bodyMedium: TextStyle(color: kOnSurface),
            bodySmall: TextStyle(color: kOnSurfaceMuted),
          ),
        ),
        home: AuthGate(injector: injector),
      ),
    );
  }
}
