import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:iproov_flutter/events.dart';
import '../config/config.dart';
import '../l10n/l10n.dart';
import '../services/iproov_result_handler.dart';
import '../services/iproov_service.dart';
import 'documents_page.dart';
import 'face_scan_intro_page.dart';
import 'package:permission_handler/permission_handler.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final nameController = TextEditingController();
  final companyController = TextEditingController();

  bool emailSent = false;
  bool emailConfirmed = false;
  String errorMessage = '';
  File? selectedImage;
  bool enrolSuccess = false;
  String? enrolToken;
  bool verificationFailed = false;

  final int maxRetryAttempts = 3;
  int verifyAttempts = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 100), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FaceScanIntroPage()),
      );
    });
  }

  Future<void> sendEmail() async {
    final email = emailController.text.trim();
    _showLoadingDialog(L10n.get(context, 'sendingEmail'));

    final baseUrl = await AppConfig.getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    Navigator.pop(context);
    print("register-email response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        emailSent = true;
        errorMessage = '';
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text(L10n.get(context, 'Confirm the code sent to your email')),
          content: TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            maxLength: 5,
            decoration: InputDecoration(labelText: L10n.get(context, 'Enter 5-digit code')),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await confirmCode();
              },
              child: Text(L10n.get(context, 'confirm')),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        errorMessage = response.body;
      });
    }
  }

  Future<void> confirmCode() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    final baseUrl = await AppConfig.getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/confirm-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    print("confirm-email response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      setState(() {
        emailConfirmed = true;
        errorMessage = '';
      });
    } else {
      setState(() {
        errorMessage = response.body;
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  bool get isFormValid {
    return nameController.text.trim().isNotEmpty &&
        companyController.text.trim().isNotEmpty &&
        selectedImage != null;
  }

  Future<void> submitEnrol() async {
    final name = nameController.text.trim();
    final company = companyController.text.trim();
    final email = emailController.text.trim();

    if (!isFormValid) return;

    _showLoadingDialog(L10n.get(context, 'submittingEnrolment'));

    final baseUrl = await AppConfig.getBaseUrl();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/enrol'))
      ..fields['name'] = name
      ..fields['company'] = company
      ..fields['email'] = email
      ..files.add(await http.MultipartFile.fromPath('photo', selectedImage!.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    Navigator.pop(context);

    print("enrol response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success'].toString().toLowerCase() == 'true') {
        setState(() {
          enrolSuccess = true;
          enrolToken = json['token'];
          errorMessage = '';
        });
      } else {
        setState(() {
          errorMessage = 'Unexpected response: ${response.body}';
        });
      }
    } else {
      setState(() {
        errorMessage = response.body;
      });
    }
  }

  Future<void> launchVerify() async {
    if (enrolToken == null) return;

    _showLoadingDialog(L10n.get(context, 'startingVerification'));

    final cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted) {
        _showError(L10n.get(context, 'camera permission'));
        return;
      }
    }

    try {
      final event = await IProovService.launchWithToken(enrolToken!);

      if (!mounted) return;

      Navigator.pop(context);

      if (event is IProovEventSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentsPage(
              email: emailController.text.trim(),
              token: enrolToken!,
            ),
          ),
        );
      } else {
        verifyAttempts += 1;
        setState(() {
          verificationFailed = true;
        });

        await handleIProovResult(context: context, event: event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.get(context, 'Verification failed'))),
        );

        if (verifyAttempts >= maxRetryAttempts) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(L10n.get(context, 'limitReached')),
              content: Text(L10n.get(context, 'You failed 3 attempts of verification. No more retries left.')),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(L10n.get(context, 'ok')),
                ),
              ],
            ),
          );

          setState(() {
            emailController.clear();
            codeController.clear();
            nameController.clear();
            companyController.clear();
            selectedImage = null;
            enrolToken = null;
            emailSent = false;
            emailConfirmed = false;
            enrolSuccess = false;
            verificationFailed = false;
            verifyAttempts = 0;
          });

          if (context.mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil("/", (route) => false);
          }
        }
      }
    } catch (e, stack) {
      Navigator.pop(context);

      print("iProov exception: $e");
      print(stack);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.get(context, "Error starting iProov: $e"))),
      );
    }
  }

  Future<void> _retryVerificationFlow() async {
    final email = emailController.text.trim();

    _showLoadingDialog(L10n.get(context, 'Sending verification code...'));
    final baseUrl = await AppConfig.getBaseUrl();
    final sendRes = await http.post(
      Uri.parse('$baseUrl/auth/send-email-verify-code'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    Navigator.pop(context);

    print("send-email-verify-code response: ${sendRes.statusCode} - ${sendRes.body}");

    if (sendRes.statusCode != 200) {
      setState(() {
        errorMessage = sendRes.body;
      });
      return;
    }

    codeController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(L10n.get(context, 'confirmCode')),
        content: TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 5,
          decoration: InputDecoration(labelText: L10n.get(context, 'Enter 5-digit code')),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _confirmAndRetryWithToken();
            },
            child: Text(L10n.get(context, 'Confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndRetryWithToken() async {
    final email = emailController.text.trim();
    final code = codeController.text.trim();

    _showLoadingDialog(L10n.get(context, 'Validating code...'));
    final baseUrl = await AppConfig.getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/generate-verify-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    Navigator.pop(context);

    print("generate-verify-token response: ${response.statusCode} - ${response.body}");

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final token = json['token'];

      if (token != null) {
        setState(() {
          enrolToken = token;
          verificationFailed = false;
        });
        await launchVerify();
      } else {
        setState(() {
          errorMessage = 'Token missing in response.';
        });
      }
    } else {
      setState(() {
        errorMessage = response.body;
      });
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDisabled = enrolSuccess;

    return Scaffold(
      appBar: AppBar(title: Text(L10n.get(context, 'register'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: L10n.get(context, 'email')),
              enabled: !emailConfirmed && !allDisabled,
            ),
            const SizedBox(height: 8),
            if (!emailSent)
              ElevatedButton(
                onPressed: allDisabled ? null : sendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: Text(L10n.get(context, 'send')),
              ),
            if (emailConfirmed) ...[
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: L10n.get(context, 'name')),
                enabled: !allDisabled,
              ),
              TextField(
                controller: companyController,
                decoration: InputDecoration(labelText: L10n.get(context, 'company')),
                enabled: !allDisabled,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: allDisabled ? null : pickImage,
                icon: selectedImage != null
                    ? const Icon(Icons.check, color: Colors.white)
                    : const Icon(Icons.camera_alt, color: Colors.black),
                label: Text(
                  selectedImage != null
                      ? L10n.get(context, 'selfieTaken')
                      : L10n.get(context, 'takeSelfie'),
                  style: TextStyle(
                    color: selectedImage != null ? Colors.white : Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  selectedImage != null ? Colors.green : Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: (!allDisabled && isFormValid) ? submitEnrol : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: Text(L10n.get(context, 'send')),
              ),
            ],
            if (enrolSuccess && enrolToken != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (verifyAttempts >= maxRetryAttempts)
                    ? null
                    : () => verificationFailed
                    ? _retryVerificationFlow()
                    : launchVerify(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: Text(
                  verificationFailed
                      ? L10n.get(context, 'tryAgainWithGPA')
                      : L10n.get(context, 'verifyWithGPA'),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}