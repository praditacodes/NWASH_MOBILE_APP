import 'dart:convert';

class UserModel {
  final String id;
  final String uid;
  final String email;
  final String? name;
  final String? phone;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserModel({
    this.id = '0',
    required this.uid,
    required this.email,
    this.name,
    this.phone,
    this.photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    lastLoginAt = lastLoginAt ?? DateTime.now();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '0',
      uid: json['uid']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString(),
      phone: json['phone']?.toString(),
      photoURL: json['photoURL']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null 
          ? DateTime.tryParse(json['lastLoginAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'photoURL': photoURL,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? photoURL,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, uid: $uid, email: $email, name: $name, phone: $phone)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && 
           other.id == id && 
           other.uid == uid &&
           other.email == email;
  }

  @override
  int get hashCode => Object.hash(id, uid, email);
}