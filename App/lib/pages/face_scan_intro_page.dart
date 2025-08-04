import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

class FaceScanIntroPage extends StatefulWidget {
  const FaceScanIntroPage({super.key});

  @override
  State<FaceScanIntroPage> createState() => _FaceScanIntroPageState();
}

class _FaceScanIntroPageState extends State<FaceScanIntroPage> {
  void _showHelpGifDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L10n.get(context, 'helpTitle')),
        content: Image.asset(
          Platform.isAndroid ? 'assets/images/android.gif' : 'assets/images/iphoneX.gif',
          fit: BoxFit.cover,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.get(context, 'close')),
          ),
        ],
      ),
    );
  }

  void _showAccessibilityDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L10n.get(context, 'accessibilityInfo')),
        content: SingleChildScrollView(
          child: Text(L10n.get(context, 'accessibilityContent')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(L10n.get(context, 'close')),
          ),
        ],
      ),
    );
  }

  void _showUserTips() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        insetPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.95,
              maxWidth: MediaQuery.of(context).size.width * 0.995,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.asset(
                      'assets/images/Scanning_Tips.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L10n.get(context, 'nextScanFace'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      L10n.get(context, 'faceScanSuccessTitle'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${L10n.get(context, 'tipBrightness')} ", style: Theme.of(context).textTheme.bodyMedium),
                        GestureDetector(
                          onTap: _showHelpGifDialog,
                          child: Text(
                            L10n.get(context, 'needHelp'),
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("2. ", style: Theme.of(context).textTheme.bodyMedium),
                        GestureDetector(
                          onTap: _showUserTips,
                          child: Text(
                            L10n.get(context, 'scanTips'),
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      children: [
                        Text(
                          L10n.get(context, 'accessibilityIntro'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: _showAccessibilityDialog,
                          child: Text(
                            L10n.get(context, 'accessibilityClickHere'),
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    L10n.get(context, 'ok'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}