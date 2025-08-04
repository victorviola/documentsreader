import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iproov_flutter/events.dart';
import 'dart:convert';
import '../config/config.dart';
import '../services/iproov_service.dart';
import 'documents_page.dart';
import 'face_scan_intro_page.dart';
import '../services/iproov_result_handler.dart';
import '../l10n/l10n.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();

  bool isLoading = false;
  bool emailSent = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FaceScanIntroPage()),
      );
    });
  }

  void _showError(String message) {
    setState(() => errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _sendEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showError(L10n.get(context, 'Email cannot be empty.'));
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-email-verify-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        setState(() => emailSent = true);
        codeController.clear();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: Text(L10n.get(context, 'confirmCode')),
            content: TextField(
              controller: codeController,
              maxLength: 5,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: L10n.get(context, 'enter5DigitCode'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _verifyCodeAndLogin();
                },
                child: Text(L10n.get(context, 'confirm')),
              ),
            ],
          ),
        );
      } else {
        _showError("${L10n.get(context, 'Failed to send verification code.')} ${response.body}");
      }
    } catch (e) {
      _showError("${L10n.get(context, 'Network error')}: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _verifyCodeAndLogin() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    if (code.length != 5) {
      _showError(L10n.get(context, 'Code must be 5 digits.'));
      return;
    }

    setState(() => isLoading = true);

    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final tokenResponse = await http.post(
        Uri.parse('$baseUrl/auth/generate-verify-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      if (tokenResponse.statusCode != 200) {
        _showError(L10n.get(context, 'Invalid code.'));
        return;
      }

      final data = jsonDecode(tokenResponse.body);
      final token = data['token'];

      if (token == null) {
        _showError(L10n.get(context, 'Token missing in response.'));
        return;
      }

      final cameraStatus = await Permission.camera.status;
      if (!cameraStatus.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          _showError(L10n.get(context, 'camera permission'));
          return;
        }
      }

      final event = await IProovService.launchWithToken(token);

      if (event is IProovEventSuccess && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentsPage(email: email, token: token),
          ),
        );
      } else {
        await handleIProovResult(context: context, event: event);
      }
    } catch (e) {
      _showError("${L10n.get(context, 'Unexpected error')}: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.get(context, 'login'))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: L10n.get(context, 'email')),
              keyboardType: TextInputType.emailAddress,
              enabled: !emailSent,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _sendEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size.fromHeight(48),
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
                  : Text(L10n.get(context, 'send')),
            ),
            const SizedBox(height: 24),
            if (errorMessage.isNotEmpty) ...[
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    super.dispose();
  }
}