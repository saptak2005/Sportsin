import 'dart:convert';

class JwtService {
  static JwtService? _instance;
  static JwtService get instance => _instance ??= JwtService._();

  JwtService._();

  Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      String payload = parts[1];

      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  String? getUserId(String token) {
    final payload = decodeToken(token);
    return payload?['user_id'] ?? payload?['sub'] ?? payload?['id'];
  }

  String? getUserRole(String token) {
    final payload = decodeToken(token);
    return payload?['role'];
  }

  String? getEmail(String token) {
    final payload = decodeToken(token);
    return payload?['email'];
  }

  bool isTokenExpired(String token) {
    final payload = decodeToken(token);
    if (payload == null) return true;

    final exp = payload['exp'];
    if (exp == null) return true;

    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    return DateTime.now().isAfter(expiryDate);
  }

  Map<String, dynamic>? getUserInfo(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;

    return {
      'id': getUserId(token),
      'email': getEmail(token),
      'role': getUserRole(token),
      'exp': payload['exp'],
      'iat': payload['iat'],
      ...payload,
    };
  }
}
