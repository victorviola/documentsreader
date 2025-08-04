import 'package:flutter/material.dart';
import 'settings_page.dart';
import '../l10n/l10n.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _goToConfirmLogin(BuildContext context) {
    Navigator.pushNamed(context, '/login-page');
  }

  void _goToRegister(BuildContext context) {
    Navigator.pushNamed(context, '/register');
  }

  void _goToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(L10n.get(context, 'homeTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _goToSettings(context),
          ),
        ],
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/Main Character.png',
              height: 200,
            ),
            const SizedBox(height: 40),
            Text(
              L10n.get(context, 'appTitle'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _goToConfirmLogin(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black),
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(L10n.get(context, 'login')),
            ),
            const SizedBox(height: 24),
            Text(
              L10n.get(context, 'firstTimePrompt'),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _goToRegister(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(50),
              ),
              child: Text(L10n.get(context, 'register')),
            ),
          ],
        ),
      ),
    );
  }
}