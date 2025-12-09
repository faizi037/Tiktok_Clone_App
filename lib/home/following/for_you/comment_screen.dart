import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tiktok_app/widgets/user_data_builder.dart';

class CommentsScreen extends StatefulWidget {
  final String videoId;
  final List<Map<String, dynamic>> videos;
  final int videoIndex;
  
  const CommentsScreen({
    super.key, 
    required this.videoId,
    required this.videos,
    required this.videoIndex,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FocusNode _commentFocusNode = FocusNode();
  
  // Add the _addComment function here
  Future<void> _addComment(int videoIndex) async {
    final user = _auth.currentUser;
    if (user == null || _commentController.text.trim().isEmpty) return;

    final video = widget.videos[videoIndex];
    final videoId = video['id'];
    
    try {
      // Get user info from users collection
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      // Add comment to SAME structure as For You page
      await _firestore
          .collection('videos')
          .doc(videoId)
          .collection('comments')
          .add({
        'uid': user.uid,
        'username': userData['username'] ?? 'User',
        'userProfile': userData['profileImage'] ?? 
            'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png',
        'comment': _commentController.text.trim(),
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Update comment count (same as For You page)
      await _firestore.collection('videos').doc(videoId).update({
        'commentCount': FieldValue.increment(1),
      });
      
      // Update local state
      setState(() {
        widget.videos[videoIndex]['commentCount'] = (widget.videos[videoIndex]['commentCount'] as int) + 1;
      });
      
      _commentController.clear();
      Get.snackbar(
        "Comment Added",
        "Your comment has been posted",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Comment error: $e');
      Get.snackbar(
        "Error",
        "Failed to add comment",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Comments',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // REMOVED the actions (send button) from AppBar
      ),
      body: Column(
        children: [
          // Comments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('videos')
                  .doc(widget.videoId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // Show loading indicator
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  );
                }

                // Show error message
                if (snapshot.hasError) {
                  print("❌ Comments error: ${snapshot.error}");
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load comments',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                          ),
                          child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                // Show empty state
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comment_outlined, color: Colors.white54, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                // Show comments list
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final comment = snapshot.data!.docs[index];
                    final data = comment.data() as Map<String, dynamic>;
                    
                    return CommentTile(
                      username: data['username'],
                      comment: data['comment'],
                      timestamp: data['timestamp'],
                      likes: List<String>.from(data['likes'] ?? []),
                      commentId: comment.id,
                      videoId: widget.videoId,
                      userProfile: data['userProfile'],
                      userId: data['uid'], // Add user ID for delete functionality
                    );
                  },
                );
              },
            ),
          ),

          // Comment Input Section
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // User Avatar
                if (_auth.currentUser != null)
                  UserDataBuilder(
                    uid: _auth.currentUser!.uid,
                    builder: (context, userData) {
                      final profileImage = userData['profileImage'] ?? 
                          _auth.currentUser?.photoURL ?? 
                          'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png';
                      
                      return CircleAvatar(
                        backgroundImage: NetworkImage(profileImage),
                        radius: 20,
                      );
                    },
                  )
                else
                  const CircleAvatar(
                    backgroundImage: NetworkImage(
                      'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png',
                    ),
                    radius: 20,
                  ),
                const SizedBox(width: 12),
                
                // Comment Input Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _commentController,
                      focusNode: _commentFocusNode,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send, color: Colors.pinkAccent),
                          onPressed: () => _addComment(widget.videoIndex), // Use the new function
                        ),
                      ),
                      onSubmitted: (value) => _addComment(widget.videoIndex), // Use the new function
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

  // Original _postComment function (you can keep it or remove it since you're using _addComment)
  void _postComment() async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        'Login Required',
        'Please login to comment',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    try {
      // Add comment to Firestore
      await _firestore
          .collection('videos')
          .doc(widget.videoId)
          .collection('comments')
          .add({
        'uid': user.uid,
        'username': user.displayName ?? 'User',
        'userProfile': user.photoURL ?? 
            'https://res.cloudinary.com/dvsl8pcsi/image/upload/v1763618042/am0pdyotsw2vwobaukhx.png',
        'comment': comment,
        'likes': [],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update comment count in video document
      await _firestore.collection('videos').doc(widget.videoId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Clear input and close keyboard
      _commentController.clear();
      _commentFocusNode.unfocus();

      // Show success message
      Get.snackbar(
        'Success',
        'Comment posted!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      
    } catch (e) {
      print('❌ Comment posting error: $e');
      
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to post comment',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }
}

class CommentTile extends StatefulWidget {
  final String username;
  final String comment;
  final Timestamp timestamp;
  final List<String> likes;
  final String commentId;
  final String videoId;
  final String userProfile;
  final String userId;

  const CommentTile({
    super.key,
    required this.username,
    required this.comment,
    required this.timestamp,
    required this.likes,
    required this.commentId,
    required this.videoId,
    required this.userProfile,
    required this.userId,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _getTimeAgo() {
    final now = DateTime.now();
    final commentTime = widget.timestamp.toDate();
    final difference = now.difference(commentTime);

    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()}w';
    return '${(difference.inDays / 30).floor()}mo';
  }

  void _toggleLike() async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar(
        'Login Required',
        'Please login to like comments',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final isLiked = widget.likes.contains(user.uid);

    try {
      if (isLiked) {
        // Remove like
        await _firestore
            .collection('videos')
            .doc(widget.videoId)
            .collection('comments')
            .doc(widget.commentId)
            .update({
          'likes': FieldValue.arrayRemove([user.uid]),
        });
      } else {
        // Add like
        await _firestore
            .collection('videos')
            .doc(widget.videoId)
            .collection('comments')
            .doc(widget.commentId)
            .update({
          'likes': FieldValue.arrayUnion([user.uid]),
        });
      }
    } catch (e) {
      print('❌ Error toggling comment like: $e');
      Get.snackbar(
        'Error',
        'Failed to like comment',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _deleteComment() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Show confirmation dialog
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Delete Comment',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close dialog
              
              try {
                // Delete comment from Firestore
                await _firestore
                    .collection('videos')
                    .doc(widget.videoId)
                    .collection('comments')
                    .doc(widget.commentId)
                    .delete();

                // Decrement comment count in video document
                await _firestore.collection('videos').doc(widget.videoId).update({
                  'commentCount': FieldValue.increment(-1),
                });

                // Show success message
                Get.snackbar(
                  'Deleted',
                  'Comment deleted successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
                
              } catch (e) {
                print('❌ Error deleting comment: $e');
                Get.snackbar(
                  'Error',
                  'Failed to delete comment',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isLiked = widget.likes.contains(user?.uid);
    final isCurrentUserComment = user?.uid == widget.userId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          UserDataBuilder(
            uid: widget.userId,
            builder: (context, userData) {
              final profileImage = userData['profileImage'] ?? 
                  widget.userProfile;
              
              return CircleAvatar(
                backgroundImage: NetworkImage(profileImage),
                radius: 20,
              );
            },
          ),
          const SizedBox(width: 12),
          
          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and Time
                Row(
                  children: [
                    UserDataBuilder(
                      uid: widget.userId,
                      builder: (context, userData) {
                        final username = userData['username'] ?? widget.username;
                        return Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getTimeAgo(),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    if (isCurrentUserComment) ...[
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
                
                // Comment Text
                Text(
                  widget.comment,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Like Button and Count + Delete Button
                Row(
                  children: [
                    // Like Button
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.pinkAccent : Colors.white54,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.likes.length.toString(),
                            style: TextStyle(
                              color: isLiked ? Colors.pinkAccent : Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Delete Button (only show for current user's comments)
                    if (isCurrentUserComment)
                      GestureDetector(
                        onTap: _deleteComment,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.white54,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
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
  }
}