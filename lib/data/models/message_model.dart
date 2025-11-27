class MessageModel  {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;

  const MessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json, String id) {
    return MessageModel(
      id: id,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, userId, userName, message, timestamp];
}