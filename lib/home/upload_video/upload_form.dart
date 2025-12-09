import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tiktok_app/services/cloudinary_service.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class UploadForm extends StatefulWidget {
  final File videoFile;
  
  const UploadForm({
    super.key,
    required this.videoFile,
  });

  @override
  State<UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
  late VideoPlayerController _controller;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _songController = TextEditingController();
  
  bool _isUploading = false;
  String _uploadStatus = '';
  double _uploadProgress = 0.0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _captionController.dispose();
    _songController.dispose();
    super.dispose();
  }

  Future<void> _uploadVideoToCloudinary() async {
    if (_captionController.text.trim().isEmpty) {
      Get.snackbar(
        "Caption Required",
        "Please add a caption for your video",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        "Login Required",
        "Please login to post videos",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      setState(() {
        _isUploading = true;
        _uploadStatus = 'Preparing video...';
        _uploadProgress = 0.1;
      });



      // Generate thumbnail FIRST
      setState(() {
        _uploadStatus = 'Generating thumbnail...';
        _uploadProgress = 0.3;
      });
      
      final thumbnailUrl = await CloudinaryService.generateAndUploadThumbnail(widget.videoFile);
      print(' Thumbnail URL generated: $thumbnailUrl');

      // Upload video
      setState(() {
        _uploadStatus = 'Uploading video...';
        _uploadProgress = 0.6;
      });
      
      final videoUrl = await CloudinaryService.uploadVideo(widget.videoFile);
      print(' Video URL generated: $videoUrl');

      // Save to Firestore
      setState(() {
        _uploadStatus = 'Publishing...';
        _uploadProgress = 0.9;
      });
      
      final videoData = {
        "uid": user.uid,
        
        "caption": _captionController.text.trim(),
        "songName": _songController.text.trim().isNotEmpty 
            ? _songController.text.trim() 
            : "Original Sound",
        "videoUrl": videoUrl,
        "thumbnailUrl": thumbnailUrl, //  CRITICAL: Save thumbnail URL
        
        "likes": [],
        "commentCount": 0,
        "timestamp": FieldValue.serverTimestamp(),
        "uploadDate": DateTime.now().toIso8601String(),
      };
      
      await _firestore.collection("videos").add(videoData);
      
      // Debug print
      print(' Saved to Firestore:');
      print('   Video URL: $videoUrl');
      print('   Thumbnail URL: $thumbnailUrl');
      print('   Caption: ${_captionController.text}');

      // Success!
      setState(() {
        _uploadStatus = 'Success!';
        _uploadProgress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 800));
      
      Get.snackbar(
        "Posted Successfully! 🎉",
        "Your video is now live on TikTok",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      
      Navigator.pop(context);

    } catch (e) {
      print(' Upload error: $e');
      Get.snackbar(
        "Upload Failed",
        "Please check your internet and try again",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatus = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isUploading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isUploading ? 'Uploading...' : 'New Video',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: _isUploading ? _buildUploadProgress() : _buildUploadForm(),
    );
  }

  Widget _buildUploadProgress() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                ),
                Center(
                  child: Text(
                    '${(_uploadProgress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Text(
            _uploadStatus,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _getProgressMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getProgressMessage() {
    if (_uploadProgress < 0.4) return "Processing your video...";
    if (_uploadProgress < 0.8) return "Uploading to Cloudinary...";
    return "Almost done!";
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: Stack(
              children: [
                _controller.value.isInitialized
                    ? VideoPlayer(_controller)
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ),
                
                Positioned.fill(
                  child: IconButton(
                    icon: Icon(
                      _controller.value.isPlaying 
                          ? Icons.pause_circle_outline 
                          : Icons.play_circle_outline,
                      color: Colors.white.withOpacity(0.7),
                      size: 60,
                    ),
                    onPressed: () {
                      setState(() {
                        if (_controller.value.isPlaying) {
                          _controller.pause();
                        } else {
                          _controller.play();
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "CAPTION",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _captionController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Add a caption...",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[900],
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  "SOUND",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _songController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: "Add a sound (optional)",
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[900],
                    contentPadding: const EdgeInsets.all(16),
                    suffixIcon: Icon(
                      Icons.music_note,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.music_note, color: Colors.pinkAccent),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Use Original Sound",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      Icon(Icons.check, color: Colors.green),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _uploadVideoToCloudinary,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "POST",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}