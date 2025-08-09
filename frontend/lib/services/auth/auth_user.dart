import 'package:flutter/foundation.dart' show immutable;
import '../../models/enums.dart';

@immutable
class AuthUser {
  final String email;
  final bool isEmailVerified;
  final String id;
  final Role role;

  const AuthUser({
    required this.email,
    required this.isEmailVerified,
    required this.id,
    required this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      email: json['email'] as String,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      id: json['id'] as String,
      role: Role.fromJson(json['role'] as String),
    );
  }

  factory AuthUser.fromBackendResponse(Map<String, dynamic> response) {
    return AuthUser(
      email: response['user']['email'] as String,
      isEmailVerified: response['user']['email_verified'] as bool? ?? false,
      id: response['user']['id'] as String,
      role: Role.fromJson(response['user']['role'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'isEmailVerified': isEmailVerified,
      'id': id,
      'role': role.toJson(),
    };
  }

  Map<String, dynamic> toBackendFormat() {
    return {
      'user': {
        'email': email,
        'email_verified': isEmailVerified,
        'id': id,
        'role': role.toJson(),
      }
    };
  }

  AuthUser copyWith({
    String? email,
    bool? isEmailVerified,
    String? id,
    Role? role,
  }) {
    return AuthUser(
      email: email ?? this.email,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      id: id ?? this.id,
      role: role ?? this.role,
    );
  }
}
