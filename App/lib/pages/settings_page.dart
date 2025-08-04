import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import '../l10n/l10n.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final iproovController = TextEditingController();
  late final TextEditingController backendIpController;
  late final TextEditingController backendPortController;

  Color testButtonColor = Colors.amber;
  String testResult = '';

  @override
  void initState() {
    super.initState();

    backendIpController = TextEditingController(text: '127.0.0.1');
    backendPortController = TextEditingController(text: '8080');
    iproovController.text = AppConfig.iproovService;

    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    final baseUrl = await AppConfig.getBaseUrl();
    final uri = Uri.tryParse(baseUrl);
    final ip = uri?.host ?? '127.0.0.1';
    final port = uri?.port.toString() ?? '8080';

    setState(() {
      backendIpController.text = ip;
      backendPortController.text = port;
    });

    await _loadSettings();
    await testBackendConnection();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      backendIpController.text = prefs.getString('backendIp') ?? backendIpController.text;
      backendPortController.text = prefs.getString('backendPort') ?? backendPortController.text;
      iproovController.text = prefs.getString('iproovService') ?? AppConfig.iproovService;
    });
  }

  Future<void> testBackendConnection() async {
    final ip = backendIpController.text.trim();
    final port = backendPortController.text.trim();
    final url = Uri.parse('https://$ip:$port/healthcheck/database');

    setState(() {
      testButtonColor = Colors.amber;
      testResult = '';
    });

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (!mounted) return;

      setState(() {
        testButtonColor = response.statusCode == 200 ? Colors.green : Colors.red;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        testButtonColor = Colors.red;
      });
    }
  }

  Future<void> _saveSettings() async {
    final ip = backendIpController.text.trim();
    final port = backendPortController.text.trim();
    final iproov = iproovController.text.trim();

    // Salva os valores independentemente do health check
    await AppConfig.updateBaseUrl(ip, port);
    await AppConfig.updateIproovService(iproov);

    // Executa o health check para atualizar a cor do botão
    await testBackendConnection();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.get(context, 'settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ListTile(
              title: Text(L10n.get(context, 'darkMode')),
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (val) => themeProvider.toggleTheme(val),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(L10n.get(context, 'language')),
              trailing: DropdownButton<Locale>(
                value: localeProvider.locale,
                onChanged: (Locale? newLocale) {
                  if (newLocale != null) {
                    localeProvider.setLocale(newLocale);
                  }
                },
                items: L10n.supportedLocales.map((locale) {
                  final language = locale.languageCode == 'en' ? 'English' : 'Português';
                  return DropdownMenuItem(
                    value: locale,
                    child: Text(language),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 32),
            Text(L10n.get(context, 'iProov Service URL')),
            TextField(
              controller: iproovController,
              decoration: const InputDecoration(hintText: 'wss://...'),
              onChanged: (_) => setState(() => testButtonColor = Colors.amber),
            ),
            const SizedBox(height: 20),
            Text(L10n.get(context, 'Backend IP')),
            TextField(
              controller: backendIpController,
              decoration: const InputDecoration(hintText: '192.168.0.1 or localhost'),
              onChanged: (_) => setState(() => testButtonColor = Colors.amber),
            ),
            const SizedBox(height: 16),
            Text(L10n.get(context, 'Backend Port')),
            TextField(
              controller: backendPortController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '8080'),
              onChanged: (_) => setState(() => testButtonColor = Colors.amber),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(backgroundColor: testButtonColor),
                child: Text(L10n.get(context, 'Save')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    backendIpController.dispose();
    backendPortController.dispose();
    iproovController.dispose();
    super.dispose();
  }
}