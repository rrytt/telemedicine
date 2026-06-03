import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../core/supabase/supabase_service.dart';

class ImageViewerView extends StatelessWidget {
  const ImageViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = Get.arguments as Map<String, dynamic>;
    final String path = args['path'];
    final String name = args['name'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            onPressed: () => _saveImage(path, name),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: SupabaseService.client.storage
              .from('medical-files')
              .createSignedUrl(path, 3600),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(color: Colors.white);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Error loading image', style: TextStyle(color: Colors.white));
            }

            return InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.network(
                snapshot.data!,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 100, color: Colors.white38),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveImage(String path, String name) async {
    try {
      Get.showOverlay(
        asyncFunction: () async {
          final bytes = await SupabaseService.client.storage
              .from('medical-files')
              .download(path);
          
          final Directory directory = Platform.isAndroid 
              ? Directory('/storage/emulated/0/Download') 
              : await getApplicationDocumentsDirectory();
          
          final String filePath = '${directory.path}/$name';
          final File file = File(filePath);
          await file.writeAsBytes(bytes);
          Get.snackbar('Success', 'Image saved to: $filePath', 
              backgroundColor: Colors.green, colorText: Colors.white);
        },
        loadingWidget: const Center(child: CircularProgressIndicator()),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to save image: $e', 
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}