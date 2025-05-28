import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'config/firebase_config.dart';
import 'exporter.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/email_verification_screen.dart';
import 'layout/main_layout.dart';
import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'services/translation_service.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'models/course_model.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    if (!e.toString().contains('already exists')) rethrow;
  }

  await Hive.initFlutter();
  Hive.registerAdapter(CourseAdapter());
  await Hive.openBox<Course>('coursesBox');

  await initializeDateFormatting('ru', null);

  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('language');
  final savedTheme = prefs.getString('theme');

  final systemLocale = ui.window.locale.languageCode;
  final languageToUse = savedLanguage ??
      (['ru', 'kk', 'en'].contains(systemLocale.toLowerCase())
          ? systemLocale.toLowerCase()
          : 'en');
  await TranslationService.load(languageToUse);

  final themeMode = switch (savedTheme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  final platformBrightness = WidgetsBinding.instance.window.platformBrightness;
  SystemChrome.setSystemUIOverlayStyle(
    platformBrightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..setInitialMode(themeMode)),
        ChangeNotifierProvider(create: (_) => LanguageProvider()..setInitialLanguage(languageToUse)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Установка стиля системной панели при смене темы
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setSystemUIOverlayStyle(
        themeProvider.themeMode == ThemeMode.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      );
    });

    return MaterialApp(
      title: 'Qoldas',
      themeMode: themeProvider.themeMode,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      navigatorObservers: [routeObserver],
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          if (snapshot.hasData) {
            final user = snapshot.data!;
            if (!user.emailVerified) {
              return EmailVerificationScreen(userId: user.uid);
            }
            return MainLayout(userId: user.uid);
          }
          return const LoginScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
