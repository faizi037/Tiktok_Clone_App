import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:tiktok_app/widgets/user_data_builder.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _userVideos = [];
  bool _isLoading = true;
  int _totalLikes = 0;
  int _followerCount = 0;
  int _followingCount = 0;
  String _username = 'User';
  String _profileImage = 'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load user info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _username = userData['username'] ?? 'User';
          _profileImage = userData['profileImage'] ?? _profileImage;
          _followerCount = (userData['followers'] ?? 0) as int;
          _followingCount = (userData['following'] ?? 0) as int;
        });
      }

      // Query videos for current user
      final snapshot = await _firestore
          .collection("videos")
          .where("uid", isEqualTo: user.uid)
          .get();

      // Convert to list and sort manually
      final videosList = snapshot.docs.toList();
      
      // Sort by timestamp manually (newest first)
      videosList.sort((a, b) {
        final timeA = a.data()['timestamp'];
        final timeB = b.data()['timestamp'];
        
        if (timeA == null) return 1;
        if (timeB == null) return -1;
        
        if (timeA is Timestamp && timeB is Timestamp) {
          return timeB.compareTo(timeA);
        }
        
        return 0;
      });

      final videos = videosList.map((doc) {
        final data = doc.data();
        final likes = List<String>.from(data['likes'] ?? [])
            .where((like) => like.isNotEmpty)
            .toList();
            
        final String thumbnail = data['thumbnailUrl'] ?? data['profileImage'] ?? _profileImage;
        
        return {
          'id': doc.id,
          'videoUrl': data['videoUrl'] ?? '',
          'caption': data['caption'] ?? '',
          'likes': likes.length,
          'thumbnail': thumbnail,
          'songName': data['songName'] ?? 'Original Sound',
          'commentCount': data['commentCount'] ?? 0,
          'timestamp': data['timestamp'],
          'likedByUser': likes.contains(user.uid),
        };
      }).toList();

      setState(() {
        _userVideos = videos;
        _totalLikes = videos.fold(0, (sum, video) => sum + (video['likes'] as int));
        _isLoading = false;
      });
      
      print(' Loaded ${_userVideos.length} videos for user ${user.uid}');
      
    } catch (e) {
      print(" Error loading profile data: $e");
      Get.snackbar(
        "Error",
        "Failed to load videos",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
    }
  }

  // DELETE VIDEO FUNCTION
  Future<void> _deleteVideo(String videoId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('videos').doc(videoId).delete();
      
      // Remove from local list
      setState(() {
        _userVideos.removeWhere((video) => video['id'] == videoId);
      });
      
      Get.snackbar(
        "Deleted",
        "Video deleted successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      print(' Video $videoId deleted successfully');
      
    } catch (e) {
      print(' Delete error: $e');
      Get.snackbar(
        "Delete Failed",
        "Could not delete video",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Show delete confirmation
  void _showDeleteConfirmation(Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Delete Video?",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(video['thumbnail']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              video['caption'] ?? 'No caption',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "This action cannot be undone.",
              style: TextStyle(
                color: Colors.white70, 
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCEL",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteVideo(video['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "DELETE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Get.offAllNamed('/login');
    } catch (e) {
      print("Sign out error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          color: Colors.pinkAccent,
          backgroundColor: Colors.black,
          child: CustomScrollView(
            slivers: [
              // Profile Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Picture
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: UserDataBuilder(
                          uid: _auth.currentUser!.uid,
                          builder: (context, userData) {
                            final profileImage = userData['profileImage'] ?? _profileImage;
                            return CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(profileImage),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Username
                      UserDataBuilder(
                        uid: _auth.currentUser!.uid,
                        builder: (context, userData) {
                          final username = userData['username'] ?? _username;
                          return Text(
                            "@$username",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('Following', _followingCount),
                          _buildStat('Followers', _followerCount),
                          _buildStat('Likes', _totalLikes),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Logout Button
                      SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          onPressed: _signOut,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[900],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Logout",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Videos Grid Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Videos",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Video count
                      Text(
                        "${_userVideos.length}",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Videos Grid
              _isLoading
                  ? SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.pinkAccent,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : _userVideos.isEmpty
                      ? SliverFillRemaining(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_off_rounded,
                                color: Colors.grey[700],
                                size: 80,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "No videos yet",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                              childAspectRatio: 0.7,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final video = _userVideos[index];
                                return GestureDetector(
                                  onTap: () {
                                    // Navigate to scrollable video feed starting from this video
                                    Get.to(
                                      () => ProfileVideoFeedScreen(
                                        videos: _userVideos,
                                        initialIndex: index,
                                        username: _username,
                                        profileImage: _profileImage,
                                        userId: _auth.currentUser!.uid,
                                      ),
                                    );
                                  },
                                  onLongPress: () => _showDeleteConfirmation(video),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(video['thumbnail']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Gradient overlay
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Colors.black.withOpacity(0.3),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                        
                                        // Likes count
                                        Positioned(
                                          bottom: 6,
                                          left: 6,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.favorite,
                                                color: Colors.pinkAccent,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatCount(video['likes']),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Play icon
                                        Positioned.fill(
                                          child: Center(
                                            child: Icon(
                                              Icons.play_circle_fill_rounded,
                                              color: Colors.white.withOpacity(0.8),
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              childCount: _userVideos.length,
                            ),
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(
          _formatCount(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }
}

//  SCROLLABLE VIDEO FEED WITH COMPLETE COMMENT SYSTEM
class ProfileVideoFeedScreen extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final int initialIndex;
  final String username;
  final String profileImage;
  final String userId;

  const ProfileVideoFeedScreen({
    super.key,
    required this.videos,
    required this.initialIndex,
    required this.username,
    required this.profileImage,
    required this.userId,
  });

  @override
  State<ProfileVideoFeedScreen> createState() => _ProfileVideoFeedScreenState();
}

class _ProfileVideoFeedScreenState extends State<ProfileVideoFeedScreen> {
  late PageController _pageController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<VideoPlayerController> _controllers = [];
  int _currentIndex = 0;
  bool _isCommentVisible = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Initialize all video controllers
    for (var video in widget.videos) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(video['videoUrl']))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
      _controllers.add(controller);
    }
    
    // Play initial video
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controllers.isNotEmpty && _currentIndex < _controllers.length) {
        _controllers[_currentIndex].play();
        _controllers[_currentIndex].setLooping(true);
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    // Pause previous video
    if (_currentIndex < _controllers.length) {
      _controllers[_currentIndex].pause();
    }
    
    // Play new video
    _currentIndex = index;
    if (_currentIndex < _controllers.length) {
      _controllers[_currentIndex].play();
      _controllers[_currentIndex].setLooping(true);
    }
    
    setState(() {});
  }

  Future<void> _toggleLike(int videoIndex) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final video = widget.videos[videoIndex];
    final videoId = video['id'];
    
    try {
      final videoDoc = await _firestore.collection('videos').doc(videoId).get();
      if (videoDoc.exists) {
        final currentLikes = List<String>.from(videoDoc.data()!['likes'] ?? []);
        
        if (currentLikes.contains(user.uid)) {
          // Unlike
          currentLikes.remove(user.uid);
        } else {
          // Like
          currentLikes.add(user.uid);
        }
        
        await _firestore.collection('videos').doc(videoId).update({
          'likes': currentLikes,
        });
        
        // Update local state
        setState(() {
          widget.videos[videoIndex]['likedByUser'] = !widget.videos[videoIndex]['likedByUser'];
          widget.videos[videoIndex]['likes'] = currentLikes.length;
        });
      }
    } catch (e) {
      print('❌ Like error: $e');
    }
  }

  Future<void> _addComment(int videoIndex) async {
    final user = _auth.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    final video = widget.videos[videoIndex];
    final videoId = video['id'];
    
    try {
      // Get user info from users collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      // Add comment to Firestore
      await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .add({
        'uid': user.uid,
        'username': userData['username'] ?? 'User',
        'userProfile': userData['profileImage'] ?? widget.profileImage,
        'comment': _commentController.text.trim(),
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update comment count
      await _firestore.collection('videos').doc(videoId).update({
        'commentCount': FieldValue.increment(1),
      });
      
      // Update local state
      setState(() {
        widget.videos[videoIndex]['commentCount'] = (widget.videos[videoIndex]['commentCount'] as int) + 1;
      });
      
      // Show success message with project theme color
      Get.snackbar(
        "Success",
        "Comment posted successfully!",
        backgroundColor: Colors.pinkAccent, //  Project theme color
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
      
      _commentController.clear();
      
      // Hide keyboard
      FocusScope.of(context).unfocus();
      
    } catch (e) {
      print(' Comment error: $e');
      Get.snackbar(
        "Error",
        "Failed to post comment",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _toggleCommentLike(String commentId, int videoIndex) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final videoId = widget.videos[videoIndex]['id'];
    
    try {
      final commentDoc = await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(commentId)
          .get();
      
      if (commentDoc.exists) {
        final currentLikes = List<String>.from(commentDoc.data()!['likes'] ?? []);
        
        if (currentLikes.contains(user.uid)) {
          // Unlike comment
          await _firestore
              .collection('videos')
              .doc(videoId)
              .collection('comments')
              .doc(commentId)
              .update({
            'likes': FieldValue.arrayRemove([user.uid]),
          });
        } else {
          // Like comment
          await _firestore
              .collection('videos')
              .doc(videoId)
              .collection('comments')
              .doc(commentId)
              .update({
            'likes': FieldValue.arrayUnion([user.uid]),
          });
        }
      }
    } catch (e) {
      print(' Comment like error: $e');
    }
  }

  Future<void> _deleteComment(String commentId, int videoIndex) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final videoId = widget.videos[videoIndex]['id'];
    
    // Show confirmation dialog
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Delete Comment?",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete this comment?",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "CANCEL",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("DELETE"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    
    try {
      // Delete comment
      await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .doc(commentId)
          .delete();
      
      // Update comment count
      await _firestore.collection('videos').doc(videoId).update({
        'commentCount': FieldValue.increment(-1),
      });
      
      // Update local state
      setState(() {
        widget.videos[videoIndex]['commentCount'] = (widget.videos[videoIndex]['commentCount'] as int) - 1;
      });
      
      // Show success message
      Get.snackbar(
        "Deleted",
        "Comment deleted successfully",
        backgroundColor: Colors.pinkAccent, //  Project theme color
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
      
    } catch (e) {
      print('❌ Delete comment error: $e');
      Get.snackbar(
        "Error",
        "Failed to delete comment",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for vertical scrolling videos
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: widget.videos.length,
            itemBuilder: (context, index) {
              final video = widget.videos[index];
              final controller = index < _controllers.length ? _controllers[index] : null;
              
              return Stack(
                children: [
                  // Video Player
                  if (controller != null && controller.value.isInitialized)
                    GestureDetector(
                      onTap: () {
                        // Single tap: play/pause
                        if (controller.value.isPlaying) {
                          controller.pause();
                        } else {
                          controller.play();
                        }
                        setState(() {});
                      },
                      onDoubleTap: () {
                        // Double tap: like (TikTok style)
                        _toggleLike(index);
                        
                        // Show heart animation
                        showDialog(
                          context: context,
                          barrierColor: Colors.transparent,
                          builder: (context) => Center(
                            child: Icon(
                              Icons.favorite,
                              color: Colors.pinkAccent,
                              size: 100,
                            ),
                          ),
                        );
                        
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        });
                      },
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: VideoPlayer(controller),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.pinkAccent,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  
                  // Right side buttons (TikTok style)
                  Positioned(
                    right: 16,
                    bottom: 120,
                    child: Column(
                      children: [
                        // Profile avatar
                        GestureDetector(
                          onTap: () {
                            // Already on profile
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: UserDataBuilder(
                              uid: widget.userId,
                              builder: (context, userData) {
                                final profileImage = userData['profileImage'] ?? widget.profileImage;
                                return CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(profileImage),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        // Like button
                        Column(
                          children: [
                            IconButton(
                              onPressed: () => _toggleLike(index),
                              icon: Icon(
                                video['likedByUser'] == true
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: video['likedByUser'] == true
                                    ? Colors.pinkAccent
                                    : Colors.white,
                                size: 32,
                              ),
                            ),
                            Text(
                              _formatCount(video['likes']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // Comment button
                        Column(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _isCommentVisible = true;
                                });
                              },
                              icon: const Icon(
                                Icons.comment,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            Text(
                              _formatCount(video['commentCount']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // Share button
                        IconButton(
                          onPressed: () {
                            // Share functionality
                          },
                          icon: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bottom info
                  Positioned(
                    left: 16,
                    bottom: 120,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          UserDataBuilder(
                            uid: widget.userId,
                            builder: (context, userData) {
                              final username = userData['username'] ?? widget.username;
                              return Text(
                                "@$username",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          
                          // Caption
                          Text(
                            video['caption'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Song name
                          Row(
                            children: [
                              const Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                video['songName'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Back button
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: GestureDetector(
                          onTap: () => Get.back(),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Comments Section (TikTok style slide-up)
          if (_isCommentVisible)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Column(
                  children: [
                    // Comments header -  FIXED: Cancel button moved downward
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16), // More top padding
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Comments (${widget.videos[_currentIndex]['commentCount']})", //  Shows count
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8), //  Moved downward
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isCommentVisible = false;
                                });
                              },
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Comments list
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('videos')
                            .doc(widget.videos[_currentIndex]['id'])
                            .collection('comments')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(
                              child: CircularProgressIndicator(color: Colors.pinkAccent),
                            );
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    color: Colors.grey[400],
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No comments yet',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Be the first to comment!',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          final comments = snapshot.data!.docs;
                          
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              final data = comment.data() as Map<String, dynamic>;
                              final isCurrentUser = data['uid'] == widget.userId;
                              final commentLikes = List<String>.from(data['likes'] ?? []);
                              final isCommentLiked = commentLikes.contains(_auth.currentUser?.uid);
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    UserDataBuilder(
                                      uid: data['uid'],
                                      builder: (context, userData) {
                                        final profileImage = userData['profileImage'] ?? 
                                            data['userProfile'] ?? 
                                            widget.profileImage;
                                        return CircleAvatar(
                                          radius: 20,
                                          backgroundImage: NetworkImage(profileImage),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              UserDataBuilder(
                                                uid: data['uid'],
                                                builder: (context, userData) {
                                                  final username = userData['username'] ?? data['username'] ?? 'User';
                                                  return Text(
                                                    "@$username",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  );
                                                },
                                              ),
                                              if (isCurrentUser) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.pinkAccent.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text(
                                                    'You',
                                                    style: TextStyle(
                                                      color: Colors.pinkAccent,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data['comment'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                _formatTime(data['timestamp']),
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              //  WORKING Comment Like Button
                                              GestureDetector(
                                                onTap: () => _toggleCommentLike(comment.id, _currentIndex),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      isCommentLiked ? Icons.favorite : Icons.favorite_border,
                                                      color: isCommentLiked ? Colors.pinkAccent : Colors.grey[400],
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      commentLikes.length.toString(),
                                                      style: TextStyle(
                                                        color: isCommentLiked ? Colors.pinkAccent : Colors.grey[400],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              //  BIGGER Delete Button for own comments
                                              if (isCurrentUser)
                                                GestureDetector(
                                                  onTap: () => _deleteComment(comment.id, _currentIndex),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete_outline,
                                                          color: Colors.red,
                                                          size: 16,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        const Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Comment input
                    Container(
                      color: Colors.grey[900],
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          if (_auth.currentUser != null)
                            UserDataBuilder(
                              uid: _auth.currentUser!.uid,
                              builder: (context, userData) {
                                final profileImage = userData['profileImage'] ?? widget.profileImage;
                                return CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(profileImage),
                                );
                              },
                            )
                          else
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(widget.profileImage),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Add a comment...",
                                hintStyle: TextStyle(color: Colors.grey[500]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[800],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (value) => _addComment(_currentIndex),
                            ),
                          ),
                          const SizedBox(width: 12),
                          //  Send button with project theme color
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _commentController.text.trim().isNotEmpty
                                  ? Colors.pinkAccent // Project theme color when active
                                  : Colors.grey[700],
                            ),
                            child: IconButton(
                              onPressed: () => _addComment(_currentIndex),
                              icon: Icon(
                                Icons.send,
                                color: _commentController.text.trim().isNotEmpty
                                    ? Colors.white
                                    : Colors.grey[400],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    try {
      DateTime time;
      if (timestamp is Timestamp) {
        time = timestamp.toDate();
      } else if (timestamp is String) {
        time = DateTime.parse(timestamp);
      } else {
        return 'Just now';
      }
      
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inSeconds < 60) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      
      return '${time.day}/${time.month}/${time.year}';
    } catch (e) {
      return 'Just now';
    }
  }
}