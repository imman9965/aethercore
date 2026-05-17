import 'package:flutter/material.dart';

import '../core/colors/colors.dart';
import '../di/injector.dart';
import 'auth_gate.dart';

class AetherApp extends StatelessWidget {
  const AetherApp({super.key, required this.injector});

  final Injector injector;



  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = const ColorScheme.light(
      primary:AppColors.kPrimary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.kSurfaceContainer,
      onPrimaryContainer: AppColors.kPrimaryDark,
      secondary:AppColors. kPrimaryLight,
      onSecondary: Colors.white,
      tertiary:AppColors. kAccentCyan,
      onTertiary:AppColors. kPrimaryDark,
      surface: AppColors.kSurface,
      onSurface: AppColors.kOnSurface,
      surfaceContainerHighest:AppColors. kSurfaceContainer,
      onSurfaceVariant:AppColors. kOnSurfaceMuted,
      outline: AppColors.kOutline,
      outlineVariant: AppColors.kOutline,
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
          scaffoldBackgroundColor: AppColors.kSurfaceSubtle,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
            foregroundColor:AppColors. kOnSurface,
            titleTextStyle: TextStyle(
              color:AppColors. kOnSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          cardTheme: CardThemeData(
            color: AppColors.kSurface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.kOutline),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor:AppColors. kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.kOutline,
              disabledForegroundColor: AppColors.kOnSurfaceMuted,
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
            fillColor: AppColors.kSurface,
            hintStyle: const TextStyle(color: AppColors.kOnSurfaceMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color:AppColors. kOutline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.kOutline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.kPrimary, width: 1.6),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.kOutline,
            thickness: 1,
            space: 1,
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color:AppColors. kOnSurface),
            bodyMedium: TextStyle(color:AppColors. kOnSurface),
            bodySmall: TextStyle(color:AppColors. kOnSurfaceMuted),
          ),
        ),
        home: AuthGate(injector: injector),
      ),
    );
  }
}
