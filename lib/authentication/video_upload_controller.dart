import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class VideoUploadController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadVideoWithUrls({
    required String videoUrl,
    required String thumbUrl,
    required String caption,
    required String songName, required String thumbnailUrl,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        Get.snackbar("Error", "User not logged in",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      await _firestore.collection("videos").add({
        "uid": user.uid,
        "username": user.email,
        "caption": caption,
        "songName": songName,
        "videoUrl": videoUrl,
        "thumbnailUrl": thumbUrl,
        "likes": [],
        "timestamp": FieldValue.serverTimestamp(),
      });

      Get.snackbar(
        "Success",
        "Video posted successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
