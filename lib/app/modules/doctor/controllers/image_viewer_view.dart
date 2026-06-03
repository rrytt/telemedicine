import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/supabase/supabase_service.dart';

class ImageViewerView extends StatelessWidget {
  const ImageViewerView({super.key});

  Future<void> _downloadImage(String path, String name) async {
    try {
      // تحميل الملف كبيانات (Bytes) من Supabase
      await SupabaseService.client.storage
          .from('medical-files')
          .download(path);
      
      // هنا يمكن استخدام package مثل 'gal' أو 'image_gallery_saver' لحفظها في الاستوديو
      // أو ببساطة عرض رسالة نجاح لمحاكاة العملية حالياً
      Get.snackbar('التحميل', 'تم تحميل الملف $name بنجاح (سيتم الحفظ في المعرض)');
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل الملف: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>;
    final String url = args['url'];
    final String path = args['path'];
    final String name = args['name'];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(name, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _downloadImage(path, name),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true, 
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: path,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image, color: Colors.red, size: 50),
                  const SizedBox(height: 10),
                  Text("فشل التحميل: $error", 
                       style: const TextStyle(color: Colors.white, fontSize: 12),
                       textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}