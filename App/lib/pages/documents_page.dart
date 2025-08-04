import 'package:flutter/material.dart';
import 'pdf_viewer_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/config.dart';
import '../l10n/l10n.dart';

class DocumentsPage extends StatefulWidget {
  final String email;
  final String token;
  const DocumentsPage({super.key, required this.email, required this.token});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<Map<String, String>> documents = [];
  String error = '';
  bool loading = false;
  bool loaded = false;

  Future<void> getDocuments() async {
    setState(() {
      loading = true;
      error = '';
      documents = [];
    });

    try {
      final baseUrl = await AppConfig.getBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/documents/list'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email, 'token': widget.token}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> result = jsonDecode(response.body);
        setState(() {
          documents = result
              .map<Map<String, String>>((e) => {
            "title": e["title"] ?? L10n.get(context, 'Untitled'),
            "link": e["link"] ?? ""
          })
              .toList();
          loaded = true;
        });
      } else {
        setState(() {
          error = response.body;
          loaded = true;
        });
      }
    } catch (e) {
      setState(() {
        error = '${L10n.get(context, 'Failed to connect')}: $e';
        loaded = true;
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.get(context, 'Documents'))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: error.isNotEmpty
                  ? Center(child: Text(error, style: const TextStyle(color: Colors.red)))
                  : documents.isEmpty && !loaded
                  ? Center(child: Text(L10n.get(context, 'Please retrieve the documents')))
                  : ListView.builder(
                itemCount: documents.length,
                itemBuilder: (context, index) {
                  final doc = documents[index];
                  return ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(doc["title"] ?? '${L10n.get(context, 'Document')} ${index + 1}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PdfViewerPage(
                            url: doc["link"] ?? "",
                            title: doc["title"] ?? L10n.get(context, 'Document'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!loaded || documents.isEmpty)
                  ElevatedButton(
                    onPressed: loading ? null : getDocuments,
                    child: loading
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator())
                        : Text(L10n.get(context, 'Get Documents')),
                  ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.get(context, 'Close')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}