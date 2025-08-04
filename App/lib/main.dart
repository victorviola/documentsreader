import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:iproov_flutter_app/l10n/l10n.dart';
import 'package:iproov_flutter_app/providers/locale_provider.dart';
import 'package:iproov_flutter_app/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'config/config.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/register_page.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadConfig();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp(
          title: 'iProov Flutter App',
          theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
          locale: localeProvider.locale,
          supportedLocales: L10n.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          initialRoute: '/',
          routes: {
            '/': (context) => const HomePage(),
            '/register': (context) => const RegisterPage(),
            '/login-page': (_) => const LoginPage(),
          },
        );
      },
    );
  }
}
