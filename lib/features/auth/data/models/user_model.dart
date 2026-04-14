import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String role; // admin | client
  final String? name;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        id:        map['id'] as String,
        email:     map['email'] as String,
        role:      map['role'] as String? ?? 'client',
        name:      map['name'] as String?,
        phone:     map['phone'] as String?,
        avatarUrl: map['avatar_url'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id':         id,
        'email':      email,
        'role':       role,
        'name':       name,
        'phone':      phone,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatarUrl,
    String? role,
  }) =>
      UserModel(
        id:        id,
        email:     email,
        role:      role ?? this.role,
        name:      name ?? this.name,
        phone:     phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        createdAt: createdAt,
      );

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props =>
      [id, email, role, name, phone, avatarUrl, createdAt];
}

