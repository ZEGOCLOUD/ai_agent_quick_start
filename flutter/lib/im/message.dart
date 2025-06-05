class ZegoIMMessage {
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final int orderKey;

  ZegoIMMessage({
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    required this.orderKey,
  });

  factory ZegoIMMessage.fromJson(Map<String, dynamic> json) {
    return ZegoIMMessage(
      content: json['content'] as String,
      isFromUser: json['isFromUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      orderKey: json['orderKey'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isFromUser': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'orderKey': orderKey,
    };
  }
}
