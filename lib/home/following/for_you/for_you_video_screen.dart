import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_app/home/following/for_you/comment_screen.dart';
import 'package:tiktok_app/widgets/user_data_builder.dart';
import 'package:video_player/video_player.dart';

class ForYouVideoScreen extends StatefulWidget {
  const ForYouVideoScreen({Key? key}) : super(key: key);

  @override
  State<ForYouVideoScreen> createState() => _ForYouVideoScreenState();
}

class _ForYouVideoScreenState extends State<ForYouVideoScreen> {
  final PageController _pageController = PageController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Map<String, dynamic>> _videos = [];
  List<VideoPlayerController?> _videoControllers = [];
  bool _loading = true;
  int _currentPage = 0;
  
  // Video controls
  List<bool> _showVideoControls = [];
  List<Timer?> _controlHideTimers = [];
  List<double> _videoProgress = [];
  
  // Album rotation
  double _albumRotation = 0.0;
  Timer? _albumTimer;

  @override
  void initState() {
    super.initState();
    _loadVideosFromFirestore();
    _startAlbumRotation();
  }

  void _startAlbumRotation() {
    _albumTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _albumRotation += 0.02;
        });
      }
    });
  }

  Future<void> _loadVideosFromFirestore() async {
    try {
      print("🔄 Loading videos from Firestore...");
      
      final snap = await _firestore
          .collection('videos')
          .orderBy('timestamp', descending: true)
          .get();

      if (snap.docs.isNotEmpty) {
        _videos = snap.docs.map((doc) {
          final data = doc.data();
          final likes = List<String>.from(data['likes'] ?? [])
            .where((like) => like.isNotEmpty)
            .toList();
          
          return {
            'id': doc.id,
            'uid': data['uid'],
            'username': data['username'],
            'caption': data['caption'],
            'songName': data['songName'],
            'videoUrl': 'https://res.cloudinary.com/dvsl8pcsi/video/upload/v1763618169/jldhxrshcj7axmi9gyax.mp4',
            'profileImage': data['profileImage'] ?? 'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png',
            'likes': likes,
            'commentCount': data['commentCount'] ?? 0,
          };
        }).toList();
        
        print("✅ Loaded ${_videos.length} videos from Firestore");
        
        // Initialize video controls
        _showVideoControls = List.generate(_videos.length, (index) => false);
        _videoProgress = List.generate(_videos.length, (index) => 0.0);
        _controlHideTimers = List.generate(_videos.length, (index) => null);
        
        await _initializeAllVideos();
      } else {
        _videos = [
          {
            'id': 'demo-video',
            'uid': 'demo',
            'username': 'Faizan',
            'caption': 'My first TikTok video! 🎬',
            'songName': 'Trending Sound',
            'videoUrl': 'https://res.cloudinary.com/dvsl8pcsi/video/upload/v1763618169/jldhxrshcj7axmi9gyax.mp4',
            'profileImage': 'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png',
            'likes': [],
            'commentCount': 0,
          }
        ];
        
        // Initialize video controls for demo video
        _showVideoControls = [false];
        _videoProgress = [0.0];
        _controlHideTimers = [null];
        
        await _initializeAllVideos();
      }

      setState(() {
        _loading = false;
      });

    } catch (e) {
      print("❌ Firestore error: $e");
      _videos = [
        {
          'id': 'demo-video',
          'uid': 'demo',
          'username': 'Faizan',
          'caption': 'My first TikTok video! 🎬',
          'songName': 'Trending Sound',
          'videoUrl': 'https://res.cloudinary.com/dvsl8pcsi/video/upload/v1763618169/jldhxrshcj7axmi9gyax.mp4',
          'profileImage': 'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png',
          'likes': [],
          'commentCount': 0,
        }
      ];
      
      // Initialize video controls for demo video
      _showVideoControls = [false];
      _videoProgress = [0.0];
      _controlHideTimers = [null];
      
      await _initializeAllVideos();
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _initializeAllVideos() async {
    for (var controller in _videoControllers) {
      controller?.dispose();
    }
    _videoControllers.clear();

    print("🎬 Initializing ${_videos.length} videos...");
    
    for (int i = 0; i < _videos.length; i++) {
      try {
        final videoUrl = _videos[i]['videoUrl'];
        print("🎬 Initializing video $i: $videoUrl");
        
        final controller = VideoPlayerController.network(videoUrl);
        await controller.initialize();
        controller.setLooping(true);
        
        // Add listener for video progress
        controller.addListener(() {
          if (mounted && controller.value.isInitialized) {
            setState(() {
              _videoProgress[i] = controller.value.position.inMilliseconds / 
                                controller.value.duration.inMilliseconds;
            });
          }
        });
        
        _videoControllers.add(controller);
        
        print("✅ Video $i initialized successfully!");
        
      } catch (e) {
        print("❌ Video $i initialization failed: $e");
        _videoControllers.add(null);
        
        Get.snackbar(
          "Video Error",
          "Failed to load video",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    }

    if (_videoControllers.isNotEmpty && _videoControllers[0] != null) {
      _videoControllers[0]!.play();
      print("▶️ First video playing...");
    }
  }

  void _togglePlayPause(int videoIndex) {
    final controller = _videoControllers[videoIndex];
    if (controller != null && controller.value.isInitialized) {
      if (controller.value.isPlaying) {
        controller.pause();
        // Show controls when pausing
        _showControls(videoIndex);
        print("⏸️ Video $videoIndex paused");
      } else {
        controller.play();
        // Hide controls when playing
        _hideControls(videoIndex);
        print("▶️ Video $videoIndex playing");
      }
    }
  }

  void _showControls(int videoIndex) {
    // Cancel existing hide timer
    _controlHideTimers[videoIndex]?.cancel();
    
    setState(() {
      _showVideoControls[videoIndex] = true;
    });
  }

  void _hideControls(int videoIndex) {
    _controlHideTimers[videoIndex]?.cancel();
    
    setState(() {
      _showVideoControls[videoIndex] = false;
    });
  }

  void _seekToPosition(int videoIndex, double position) {
    final controller = _videoControllers[videoIndex];
    if (controller != null && controller.value.isInitialized) {
      // Update progress bar immediately for better UX
      setState(() {
        _videoProgress[videoIndex] = position;
      });
      
      final duration = controller.value.duration;
      final newPosition = duration * position;
      controller.seekTo(newPosition);
    }
  }

  void _toggleLike(int videoIndex) async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        "Login Required",
        "Please login to like videos",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final video = _videos[videoIndex];
    final isLiked = video['likes'].contains(user.uid);
    
    print("❤️ Toggling like - Currently liked: $isLiked");
    
    try {
      if (isLiked) {
        await _firestore.collection('videos').doc(video['id']).update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
        setState(() {
          _videos[videoIndex]['likes'] = List<String>.from(video['likes'])
            ..remove(user.uid);
        });
        print("❤️ Like removed");
      } else {
        await _firestore.collection('videos').doc(video['id']).update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
        setState(() {
          _videos[videoIndex]['likes'] = List<String>.from(video['likes'])
            ..add(user.uid);
        });
        print("❤️ Like added");
      }
    } catch (e) {
      print("❌ Error toggling like: $e");
      Get.snackbar(
        "Error",
        "Failed to update like",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _openComments(int videoIndex) {
    final video = _videos[videoIndex];
    final videoId = video['id'];
  
    print("💬 Opening comments for video: $videoId");
    print("📝 Video data: ${video['caption']}");
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentsScreen(
          videoId: videoId, videos: [], videoIndex: videoIndex,
        ),
      ),
    );
  }

  void _onPageChanged(int page) {
    print("📄 Page changed to: $page");
    
    // Cancel all control timers
    for (var timer in _controlHideTimers) {
      timer?.cancel();
    }
    
    // Hide all controls
    for (int i = 0; i < _showVideoControls.length; i++) {
      _showVideoControls[i] = false;
    }
    
    // Pause all videos
    for (var controller in _videoControllers) {
      controller?.pause();
    }
    
    // Play current video
    if (page < _videoControllers.length && _videoControllers[page] != null) {
      _videoControllers[page]!.play();
      print("▶️ Playing video $page");
    }
    
    setState(() {
      _currentPage = page;
    });
  }

  void _onDoubleTap(int videoIndex) {
    print("👆 Double tap detected on video $videoIndex");
    _toggleLike(videoIndex);
    
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => const HeartAnimation(),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _onTap(int videoIndex) {
    print("👆 Single tap detected on video $videoIndex");
    _togglePlayPause(videoIndex);
  }

  void _shareVideo(int videoIndex) {
    print("📤 Sharing video $videoIndex");
    Get.snackbar(
      "Share",
      "Share feature coming soon!",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  void dispose() {
    _albumTimer?.cancel();
    for (var timer in _controlHideTimers) {
      timer?.cancel();
    }
    for (var controller in _videoControllers) {
      controller?.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingScreen();
    }

    if (_videos.isEmpty) {
      return _buildEmptyScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          final video = _videos[index];
          final videoController = index < _videoControllers.length ? _videoControllers[index] : null;
          final isLiked = video['likes'].contains(_auth.currentUser?.uid);
          final isPlaying = videoController?.value.isPlaying ?? false;

          return GestureDetector(
            onTap: () => _onTap(index),
            onDoubleTap: () => _onDoubleTap(index),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video Player
                if (videoController == null || !videoController.value.isInitialized)
                  Container(
                    color: Colors.black,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.pinkAccent,
                            strokeWidth: 2,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Loading video...",
                            style: TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  VideoPlayer(videoController),

                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),

                // Video Controls Overlay (only show when paused)
                if (videoController != null && videoController.value.isInitialized && !isPlaying)
                  AnimatedOpacity(
                    opacity: _showVideoControls[index] ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 60,
                        ),
                      ),
                    ),
                  ),

                // Video Progress Bar (ONLY SHOW WHEN PAUSED) - WITH SEEK FUNCTIONALITY
                if (videoController != null && videoController.value.isInitialized && !isPlaying)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _ProgressBarSeekArea(
                      onSeek: (position) {
                        _seekToPosition(index, position);
                      },
                      child: Container(
                        height: 3,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: VideoProgressPainter(
                            progress: _videoProgress[index],
                            isBuffered: videoController.value.isBuffering,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Right side icons
                Positioned(
                  right: 15,
                  bottom: 120,
                  child: Column(
                    children: [
                      UserDataBuilder(
                        uid: video['uid'],
                        builder: (context, userData) {
                          final profileImage = userData['profileImage'] ?? 
                              video['profileImage'] ?? 
                              'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png';
                          
                          return CircleAvatar(
                            backgroundImage: NetworkImage(profileImage),
                            radius: 25,
                            onBackgroundImageError: (_, __) {
                              print("Failed to load profile image");
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleLike(index),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.pinkAccent : Colors.white,
                              size: 35,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatCount(video['likes'].length),
                            style: TextStyle(
                              color: isLiked ? Colors.pinkAccent : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _openComments(index),
                            child: const Icon(Icons.comment, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _formatCount(video['commentCount']),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _shareVideo(index),
                            child: const Icon(Icons.share, color: Colors.white, size: 30),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Share",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2.0,
                          ),
                        ),
                        child: Transform.rotate(
                          angle: _albumRotation,
                          child: UserDataBuilder(
                            uid: video['uid'],
                            builder: (context, userData) {
                              final profileImage = userData['profileImage'] ?? 
                                  video['profileImage'] ?? 
                                  'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png';
                                  
                              return CircleAvatar(
                                backgroundImage: NetworkImage(profileImage),
                                radius: 20,
                                onBackgroundImageError: (_, __) {
                                  print("Failed to load album image");
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom info
                Positioned(
                  left: 15,
                  bottom: 40,
                  right: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserDataBuilder(
                        uid: video['uid'],
                        builder: (context, userData) {
                          final username = userData['username'] ?? video['username'] ?? 'User';
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
                      Text(
                        video['caption'],
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.music_note, color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              video['songName'],
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '${(count / 1000000).toStringAsFixed(1)}M';
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.pinkAccent),
            SizedBox(height: 20),
            Text(
              "Loading TikTok...",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white, size: 64),
            const SizedBox(height: 20),
            const Text(
              "No videos yet",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadVideosFromFirestore,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: const Text("Try Again", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// FIXED: Separate widget for progress bar seeking to avoid context issues
class _ProgressBarSeekArea extends StatefulWidget {
  final Function(double) onSeek;
  final Widget child;

  const _ProgressBarSeekArea({
    required this.onSeek,
    required this.child,
  });

  @override
  State<_ProgressBarSeekArea> createState() => _ProgressBarSeekAreaState();
}

class _ProgressBarSeekAreaState extends State<_ProgressBarSeekArea> {
  final GlobalKey _progressKey = GlobalKey();

  void _handleSeek(DragUpdateDetails details) {
    final renderBox = _progressKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      final progress = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);
      widget.onSeek(progress);
    }
  }

  void _handleTap(TapDownDetails details) {
    final renderBox = _progressKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPosition = renderBox.globalToLocal(details.globalPosition);
      final progress = (localPosition.dx / renderBox.size.width).clamp(0.0, 1.0);
      widget.onSeek(progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _progressKey,
      onTapDown: _handleTap,
      onHorizontalDragStart: (details) => _handleSeek(DragUpdateDetails(globalPosition: details.globalPosition)),
      onHorizontalDragUpdate: _handleSeek,
      child: widget.child,
    );
  }
}

class VideoProgressPainter extends CustomPainter {
  final double progress;
  final bool isBuffered;

  VideoProgressPainter({required this.progress, required this.isBuffered});

  @override
  void paint(Canvas canvas, Size size) {
    // Background line
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, Offset(size.width, 0), backgroundPaint);

    // Progress line
    final progressPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, Offset(size.width * progress, 0), progressPaint);

    // Buffering indicator
    if (isBuffered) {
      final bufferingPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final dotOffset = Offset(size.width * progress, 0);
      canvas.drawCircle(dotOffset, 2, bufferingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HeartAnimation extends StatelessWidget {
  const HeartAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: 1,
        child: const Icon(
          Icons.favorite,
          color: Colors.pinkAccent,
          size: 80,
        ),
      ),
    );
  }
}