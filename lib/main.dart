import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_app/auth_check.dart';
import 'package:tiktok_app/home/following/for_you/video_player_screen.dart';


import 'authentication/authentication_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  Get.put(AuthenticationController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TikTok Clone',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const AuthCheck(),
        ),
        GetPage(
          name: '/video/:id',
          page: () {
            final videoId = Get.parameters['id'];
            // You'll need to fetch video data by ID
            return VideoPlayerScreen(
              videoId: videoId!,
              videoUrl: '', // Fetch from Firestore
            );
          },
        ),
        // Add more routes as needed
      ],
    );
  }
}