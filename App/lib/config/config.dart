import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String _baseUrl = 'https://localhost:8000';
  static String iproovService = 'wss://eu.rp.secure.iproov.me/ws';

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('backendIp') ?? '192.168.0.76';
    final port = prefs.getString('backendPort') ?? '8000';
    final iproov = prefs.getString('iproovService') ?? iproovService;

    _baseUrl = 'https://$ip:$port';
    iproovService = iproov;
  }

  static Future<String> getBaseUrl() async {
    await loadConfig();
    return _baseUrl;
  }

  static Future<void> updateBaseUrl(String ip, String port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backendIp', ip);
    await prefs.setString('backendPort', port);
    _baseUrl = 'https://$ip:$port';
  }

  static Future<void> updateIproovService(String iproov) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('iproovService', iproov);
    iproovService = iproov;
  }
}