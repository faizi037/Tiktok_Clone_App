import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadDetailsScreen extends StatefulWidget {
  const UploadDetailsScreen({super.key});

  @override
  State<UploadDetailsScreen> createState() => _UploadDetailsScreenState();
}

class _UploadDetailsScreenState extends State<UploadDetailsScreen> {
  final TextEditingController videoUrlController = TextEditingController(
      text:
          "https://res.cloudinary.com/dvsl8pcsi/video/upload/v1763380952/WhatsApp_Video_2025-11-17_at_12.05.34_PM_ltpwhb.mp4");
  final TextEditingController thumbnailUrlController = TextEditingController(
      text:
          "https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763383973/nns6h8emgvn0cpbjzs1r.png");
  final TextEditingController captionController = TextEditingController();
  final TextEditingController songController = TextEditingController();

  bool _isPosting = false;

  Future<void> _postVideo() async {
    if (videoUrlController.text.trim().isEmpty ||
        thumbnailUrlController.text.trim().isEmpty ||
        captionController.text.trim().isEmpty) {
      Get.snackbar(
        "Error",
        "Please fill all required fields",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      await FirebaseFirestore.instance.collection("videos").add({
        "uid": "FAKE_USER_ID", // replace with actual user id
        "username": "FaizanAsif", // replace with actual username
        "caption": captionController.text.trim(),
        "songName": songController.text.trim(),
        "videoUrl": videoUrlController.text.trim(),
        "thumbnailUrl": thumbnailUrlController.text.trim(),
        "likes": [],
        "timestamp": FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Success",
        "Video posted successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

      // Clear fields
      videoUrlController.clear();
      thumbnailUrlController.clear();
      captionController.clear();
      songController.clear();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to post video: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() {
        _isPosting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Post Video"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Video URL:",
              style: TextStyle(color: Colors.white70),
            ),
            TextField(
              controller: videoUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Paste video link here...",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Thumbnail URL:",
              style: TextStyle(color: Colors.white70),
            ),
            TextField(
              controller: thumbnailUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Paste thumbnail link here...",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Caption:",
              style: TextStyle(color: Colors.white70),
            ),
            TextField(
              controller: captionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Add a caption...",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "Song Name:",
              style: TextStyle(color: Colors.white70),
            ),
            TextField(
              controller: songController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Song used...",
                hintStyle: TextStyle(color: Colors.white38),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: _isPosting
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.pinkAccent,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _postVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        padding: const EdgeInsets.all(14),
                      ),
                      child: const Text(
                        "Post",
                        style: TextStyle(fontSize: 17, color: Colors.white),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
