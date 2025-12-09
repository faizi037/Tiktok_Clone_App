
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String videoId;
  final String userId;
  final String username;
  final String profileImage;
  final String comment;
  final DateTime timestamp;
  final List<String> likes;

  CommentModel({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.comment,
    required this.timestamp,
    required this.likes,
  });

  factory CommentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CommentModel(
      id: id,
      videoId: data['videoId'] ?? '',
      userId: data['userId'] ?? '',
      username: data['username'] ?? 'User',
      profileImage: data['profileImage'] ?? '',
      comment: data['comment'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'userId': userId,
      'username': username,
      'profileImage': profileImage,
      'comment': comment,
      'timestamp': timestamp,
      'likes': likes,
    };
  }
}