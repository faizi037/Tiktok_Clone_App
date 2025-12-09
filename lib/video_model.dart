class VideoModel {
  final String uid;
  final String username;
  final String caption;
  final String songName;
  final String videoUrl;
  final String thumbnailUrl;

  VideoModel({
    required this.uid,
    required this.username,
    required this.caption,
    required this.songName,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map) {
    return VideoModel(
      uid: map['uid'],
      username: map['username'],
      caption: map['caption'],
      songName: map['songName'],
      videoUrl: map['videoUrl'],
      thumbnailUrl: map['thumbnailUrl'],
    );
  }
}
