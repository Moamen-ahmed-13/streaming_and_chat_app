class StreamModel {
  final String id;
  final String streamerId;
  final String streamerName;
  final String? streamerPhoto;
  final String title;
  final String channelName;
  final bool isLive;
  final int viewerCount;
  final DateTime startedAt;
  final String? thumbnailUrl;

  const StreamModel({
    required this.id,
    required this.streamerId,
    required this.streamerName,
    this.streamerPhoto,
    required this.title,
    required this.channelName,
    required this.isLive,
    required this.viewerCount,
    required this.startedAt,
    this.thumbnailUrl,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json, String id) {
    return StreamModel(
      id: id,
      streamerId: json['streamerId'] as String,
      streamerName: json['streamerName'] as String,
      streamerPhoto: json['streamerPhoto'] as String?,
      title: json['title'] as String,
      channelName: json['channelName'] as String,
      isLive: json['isLive'] as bool,
      viewerCount: json['viewerCount'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streamerId': streamerId,
      'streamerName': streamerName,
      'streamerPhoto': streamerPhoto,
      'title': title,
      'channelName': channelName,
      'isLive': isLive,
      'viewerCount': viewerCount,
      'startedAt': startedAt.toIso8601String(),
      'thumbnailUrl': thumbnailUrl,
    };
  }

  @override
  List<Object?> get props => [
    id, streamerId, streamerName, streamerPhoto, 
    title, channelName, isLive, viewerCount, 
    startedAt, thumbnailUrl
  ];
}