import 'dart:io';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tiktok_app/home/upload_video/upload_form.dart'; 
class UploadVideoScreen extends StatefulWidget {
  const UploadVideoScreen({super.key});

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final ImagePicker _picker = ImagePicker();

  //  pick video from gallery
  Future<void> _pickFromGallery() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.pop(context); // close bottom sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadForm(videoFile: File(pickedFile.path)),
        ),
      );
    }
  }

  //  record video with camera
  Future<void> _recordWithCamera() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadForm(videoFile: File(pickedFile.path)),
        ),
      );
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            FadeInUp(
              duration: const Duration(milliseconds: 300),
              child: ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.pinkAccent),
                title: const Text("Get video from Gallery",
                    style: TextStyle(color: Colors.white)),
                onTap: _pickFromGallery,
              ),
            ),
            FadeInUp(
              duration: const Duration(milliseconds: 400),
              child: ListTile(
                leading: const Icon(Icons.videocam, color: Colors.pinkAccent),
                title: const Text("Make video with Camera",
                    style: TextStyle(color: Colors.white)),
                onTap: _recordWithCamera,
              ),
            ),
            const Divider(color: Colors.white24),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: ListTile(
                leading: const Icon(Icons.cancel, color: Colors.redAccent),
                title:
                    const Text("Cancel", style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/upload.png", width: 230),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: _showUploadOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
              ),
              child: const Text(
                "Upload New Video",
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
