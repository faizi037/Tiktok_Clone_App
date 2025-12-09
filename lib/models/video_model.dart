
import 'package:cloud_firestore/cloud_firestore.dart';

class VideoModel {
  final String id;
  final String uid;
  final String username;
  final String caption;
  final String songName;
  final String videoUrl;
  final String thumbnailUrl;
  final String profileImage;
  final DateTime timestamp;
  final List<String> likes;
  final int commentCount;

  VideoModel({
    required this.id,
    required this.uid,
    required this.username,
    required this.caption,
    required this.songName,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.profileImage,
    required this.timestamp,
    required this.likes,
    required this.commentCount,
  });

  factory VideoModel.fromFirestore(String id, Map<String, dynamic> data) {
    return VideoModel(
      id: id,
      uid: data['uid'] ?? '',
      username: data['username'] ?? 'User',
      caption: data['caption'] ?? '',
      songName: data['songName'] ?? 'Original Sound',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      profileImage: data['profileImage'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'caption': caption,
      'songName': songName,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'profileImage': profileImage,
      'timestamp': timestamp,
      'likes': likes,
      'commentCount': commentCount,
    };
  }
}