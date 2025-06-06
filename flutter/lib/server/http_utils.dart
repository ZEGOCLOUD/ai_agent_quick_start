import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// HTTP 响应基类
class HttpResponse<T> {
  final int code;
  final String message;
  final String? requestId;
  final T? data;

  HttpResponse({
    required this.code,
    required this.message,
    this.requestId,
    this.data,
  });

  bool get isSuccess => code == 0;

  factory HttpResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    debugPrint('解析响应数据: $json');
    return HttpResponse(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String? ?? '未知错误',
      requestId: json['requestId'] as String?,
      data: fromJson(json),
    );
  }

  factory HttpResponse.error(String message, {int code = -1}) {
    debugPrint('HTTP错误: code=$code, message=$message');
    return HttpResponse(code: code, message: message);
  }
}

/// HTTP 请求工具类
class HttpUtil {
  static Future<HttpResponse<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    debugPrint('发起GET请求: url=$url, headers=$headers');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
      );

      debugPrint(
          'GET响应: statusCode=${response.statusCode}, body=${response.body}');

      if (response.statusCode != 200) {
        return HttpResponse.error(
          '请求失败: statusCode=${response.statusCode}',
          code: response.statusCode,
        );
      }

      try {
        final json = jsonDecode(response.body);
        if (json == null) {
          return HttpResponse.error('解析响应数据失败: response.body=${response.body}');
        }

        if (fromJson != null) {
          return HttpResponse.fromJson(json, fromJson);
        } else {
          return HttpResponse(
            code: json['code'] as int? ?? 0,
            message: json['message'] as String? ?? '',
            requestId: json['requestId'] as String?,
            data: json as T,
          );
        }
      } catch (e) {
        debugPrint('解析GET响应失败: $e');
        return HttpResponse.error('解析响应数据失败: $e');
      }
    } catch (e) {
      debugPrint('GET请求失败: $e');
      return HttpResponse.error('网络请求失败: $e');
    }
  }

  static Future<HttpResponse<T>> post<T>(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    debugPrint('发起POST请求: url=$url, headers=$headers, body=$body');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers ?? {'Content-Type': 'application/json'},
        body: body != null ? jsonEncode(body) : null,
      );

      debugPrint(
          'POST响应: statusCode=${response.statusCode}, body=${response.body}');

      if (response.statusCode != 200) {
        return HttpResponse.error(
          '请求失败: statusCode=${response.statusCode}',
          code: response.statusCode,
        );
      }

      try {
        final json = jsonDecode(response.body);
        if (json == null) {
          return HttpResponse.error('解析响应数据失败: response.body=${response.body}');
        }

        if (fromJson != null) {
          return HttpResponse.fromJson(json, fromJson);
        } else {
          return HttpResponse(
            code: json['code'] as int? ?? 0,
            message: json['message'] as String? ?? '',
            requestId: json['requestId'] as String?,
            data: json as T,
          );
        }
      } catch (e) {
        debugPrint('解析POST响应失败: $e');
        return HttpResponse.error('解析响应数据失败: $e');
      }
    } catch (e) {
      debugPrint('POST请求失败: $e');
      return HttpResponse.error('网络请求失败: $e');
    }
  }
}
