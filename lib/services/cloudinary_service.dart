import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Uploads images to Cloudinary using an unsigned upload preset.
///
/// Implemented with a plain multipart request so it works on web (the
/// `cloudinary_public` package depends on `dart:io` and cannot).
class CloudinaryService {
  static const String cloudName = 'smgil6o9';
  static const String uploadPreset = 'inkvault_cloud';

  /// Uploads [file] and returns the hosted `secure_url`.
  Future<String> uploadProfileImage(XFile file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name.isEmpty ? 'inkvault_profile.jpg' : file.name,
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('Image upload failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    final String url = decoded['secure_url']?.toString() ?? '';
    if (url.isEmpty) {
      throw Exception('Image upload failed: no URL returned.');
    }
    return url;
  }
}
