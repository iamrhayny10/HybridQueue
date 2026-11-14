// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/auth_service.dart';
import 'services/queue_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:           Colors.transparent,
    statusBarIconBrightness:  Brightness.dark,
  ));
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => QueueService()),
      ],
      child: const GRCQueueApp(),
    ),
  );
}

class GRCQueueApp extends StatelessWidget {
  const GRCQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.interTextTheme().copyWith(
      bodyLarge:   GoogleFonts.inter(fontSize: 16),
      bodyMedium:  GoogleFonts.inter(fontSize: 15),
      bodySmall:   GoogleFonts.inter(fontSize: 13),
      labelLarge:  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.inter(fontSize: 13),
      labelSmall:  GoogleFonts.inter(fontSize: 12),
    );
    return MaterialApp(
      title:                    'GRC Queue Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3:          true,
        colorScheme: ColorScheme.fromSeed(
          seedColor:  const Color(0xFF1A56DB),
          brightness: Brightness.light,
        ),
        textTheme:             base,
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        appBarTheme: AppBarTheme(
          backgroundColor:    Colors.white,
          foregroundColor:    const Color(0xFF111111),
          elevation:          0,
          surfaceTintColor:   Colors.transparent,
          titleTextStyle: GoogleFonts.inter(
            fontSize:       20,
            fontWeight:     FontWeight.w600,
            color:          const Color(0xFF111111),
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A56DB),
            foregroundColor: Colors.white,
            minimumSize:     const Size(double.infinity, 54),
            elevation:       0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontSize:   16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF555555),
            minimumSize:     const Size(double.infinity, 54),
            side:            const BorderSide(color: Color(0xFFDDDDDD)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontSize:   16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled:      true,
          fillColor:   Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   const BorderSide(color: Color(0xFF1A56DB), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:   const BorderSide(color: Color(0xFFEF4444), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical:   16,
          ),
          hintStyle:  GoogleFonts.inter(
            color:    const Color(0xFFAAAAAA),
            fontSize: 15,
          ),
          labelStyle: GoogleFonts.inter(fontSize: 15),
        ),
        cardTheme: CardThemeData(
          color:     Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side:         const BorderSide(color: Color(0xFFE5E5E0)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color:     Color(0xFFE5E5E0),
          thickness: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior:            SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
