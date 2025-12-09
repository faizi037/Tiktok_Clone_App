import 'package:flutter/material.dart';
import 'package:tiktok_app/home/following/for_you/for_you_video_screen.dart';
import 'package:tiktok_app/home/following/profile/profile_screen.dart';
import 'package:tiktok_app/home/search/search_screen.dart';
import 'package:tiktok_app/home/upload_video/upload_custom_icon.dart';
import 'package:tiktok_app/home/following/followings_video_screen.dart';
import 'package:tiktok_app/home/upload_video/upload_video_screen.dart'; 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ForYouVideoScreen(),
    const SearchScreen(),
    const UploadVideoScreen(), 
    const FollowingsVideoScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: "Discover"),
          BottomNavigationBarItem(
            icon: UploadCustomIcon(),
            label: "",
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.video_library), label: "Following"),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Me"),
        ],
      ),
    );
  }
}
