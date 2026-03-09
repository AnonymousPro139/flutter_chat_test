import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For opening PDFs/Files

class MediaViewerScreen extends StatelessWidget {
  final String uri;
  final String fileName;
  final bool isImage;

  const MediaViewerScreen({
    super.key,
    required this.uri,
    this.fileName = "File",
    required this.isImage,
  });

  Future<void> _openFile() async {
    final url = Uri.parse(uri);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: isImage
            ? InteractiveViewer(
                child: Image.network(
                  uri,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const CircularProgressIndicator(),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    size: 100,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _openFile,
                    child: const Text("Open File"),
                  ),
                ],
              ),
      ),
    );
  }
}
