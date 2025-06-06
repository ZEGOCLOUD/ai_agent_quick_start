import 'package:flutter/cupertino.dart';

/// Token 响应类
class ZegoTokenResponse {
  final String token;
  final String userId;
  final double expireTime;

  ZegoTokenResponse({
    required this.token,
    required this.userId,
    required this.expireTime,
  });

  factory ZegoTokenResponse.fromJson(Map<String, dynamic> json) {
    debugPrint('解析Token响应: $json');
    return ZegoTokenResponse(
      token: json['token'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      expireTime: (json['expire_time'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
