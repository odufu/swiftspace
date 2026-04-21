import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const String cloudName = 'dqbz69nmq';
  static const String uploadPreset = 'swiftspace'; 
  
  final Dio _dio = Dio();

  Future<String?> uploadMedia({
    required XFile file,
    required String folder,
    bool isVideo = false,
    Function(double)? onProgress,
  }) async {
    try {
      final resourceType = isVideo ? 'video' : 'image';
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload';

      FormData formData;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: file.name),
          'upload_preset': uploadPreset,
          'folder': folder,
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: file.name),
          'upload_preset': uploadPreset,
          'folder': folder,
        });
      }

      final response = await _dio.post(
        url,
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0 && onProgress != null) {
            onProgress(sent / total);
          }
        },
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      if (e is DioException) {
        debugPrint('Response: ${e.response?.data}');
      }
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages(List<XFile> files, String folder, {Function(int, double)? onIndividualProgress}) async {
    List<String> urls = [];
    for (int i = 0; i < files.length; i++) {
      final url = await uploadMedia(
        file: files[i], 
        folder: folder,
        onProgress: (progress) {
          if (onIndividualProgress != null) {
            onIndividualProgress(i, progress);
          }
        },
      );
      if (url != null) urls.add(url);
    }
    return urls;
  }
}
