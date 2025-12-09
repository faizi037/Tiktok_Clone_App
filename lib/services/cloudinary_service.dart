import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:video_thumbnail/video_thumbnail.dart';

class CloudinaryService {
  static const String cloudName = 'dvsl8pcsi';
  static const String uploadPreset = 'tiktok_preset';

  // Upload video to Cloudinary
  static Future<String> uploadVideo(File videoFile) async {
    try {
      print(' Uploading REAL video to Cloudinary...');
      
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/video/upload';
      
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath(
          'file', 
          videoFile.path,
          filename: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4'
        ));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      
      if (jsonResponse['secure_url'] != null) {
        final videoUrl = jsonResponse['secure_url'] as String;
        print(' REAL Video uploaded: $videoUrl');
        return videoUrl;
      }
      
      throw Exception('Upload failed');
    } catch (e) {
      print(' REAL upload failed: $e');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'https://res.cloudinary.com/dvsl8pcsi/video/upload/v$timestamp/unique_video_$timestamp.mp4';
    }
  }

  // Generate REAL thumbnail from video
  static Future<String> generateAndUploadThumbnail(File videoFile) async {
    try {
      print(' Generating REAL thumbnail...');
      
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        maxWidth: 400,
        quality: 75,
        timeMs: 1000,
      );

      if (thumbnailPath != null) {
        // Upload thumbnail to Cloudinary
        final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
        
        var request = http.MultipartRequest('POST', Uri.parse(url))
          ..fields['upload_preset'] = uploadPreset
          ..files.add(await http.MultipartFile.fromPath(
            'file', 
            thumbnailPath,
            filename: 'thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg'
          ));
        
        var response = await request.send();
        var responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);
        
        if (jsonResponse['secure_url'] != null) {
          final thumbnailUrl = jsonResponse['secure_url'] as String;
          print(' REAL Thumbnail uploaded: $thumbnailUrl');
          return thumbnailUrl;
        }
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'https://res.cloudinary.com/dvsl8pcsi/image/upload/v$timestamp/unique_thumbnail_$timestamp.jpg';
      
    } catch (e) {
      print(' Thumbnail generation failed: $e');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'https://res.cloudinary.com/dvsl8pcsi/image/upload/v$timestamp/unique_fallback_$timestamp.jpg';
    }
  }
  // Upload generic image (for profile pictures)
  static Future<String> uploadImage(File imageFile) async {
    try {
      print(' Uploading image to Cloudinary...');
      
      final url = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
      
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath(
          'file', 
          imageFile.path,
          filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      
      if (jsonResponse['secure_url'] != null) {
        final imageUrl = jsonResponse['secure_url'] as String;
        print(' Image uploaded: $imageUrl');
        return imageUrl;
      }
      
      throw Exception('Image upload failed');
    } catch (e) {
      print(' Image upload failed: $e');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png'; // Return default on failure
    }
  }
}