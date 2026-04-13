// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';  // ← ADD THIS IMPORT
import 'package:nyota/firebase_options.dart';
import 'package:nyota/screens/theme_provider.dart';
import 'package:nyota/screens/authwrapper.dart';
import 'package:nyota/screens/login_screen.dart';
import 'package:nyota/screens/signup_screen.dart';
import 'package:nyota/screens/maindashboard_screen.dart';
import 'package:nyota/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NyotaApp());
}

class NyotaApp extends StatelessWidget {
  const NyotaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,

            
            fontSizeResolver: (fontSize, instance) {
              final scale = instance.scaleText;
              final cappedScale = scale.clamp(0.85, 1.28);
              return fontSize * cappedScale;
            },

            builder: (context, child) {
              return MaterialApp(
                title: 'Nyota – Math is Easy',
                debugShowCheckedModeBanner: false,

                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),

               
                themeMode: themeProvider.themeMode,

                
                home: const AuthWrapper(),

               
                routes: {
                  '/login': (context) => const NyotaLoginPage(),
                  '/signup': (context) => const SignupScreen(),
                  '/main-dashboard': (context) => const MainDashboardScreen(),
                  
                },
              );
            },
          );
        },
      ),
    );
  }
}