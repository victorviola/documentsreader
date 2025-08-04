import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class PdfViewerPage extends StatefulWidget {
  final String url;
  final String title;

  const PdfViewerPage({super.key, required this.url, required this.title});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  String? localPath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    downloadPdf();
  }

  Future<void> downloadPdf() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      final bytes = response.bodyBytes;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(bytes, flush: true);

      setState(() {
        localPath = file.path;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : localPath != null
          ? PDFView(
        filePath: localPath!,
      )
          : const Center(child: Text("Could not load PDF")),
    );
  }
}