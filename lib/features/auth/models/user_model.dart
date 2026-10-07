class UserModel {
  final int id;
  final String name;
  final String? login;
  final String? photoUrl;
  final int? onWorkStatus;
  final Role? role;

  UserModel({
    required this.id,
    required this.name,
    this.login,
    this.photoUrl,
    this.onWorkStatus,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      login: json['login'],
      photoUrl: json['photo_url'],
      onWorkStatus: json['on_work_status'],
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
    );
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? login,
    String? photoUrl,
    int? onWorkStatus,
    Role? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      login: login ?? this.login,
      photoUrl: photoUrl ?? this.photoUrl,
      onWorkStatus: onWorkStatus ?? this.onWorkStatus,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'login': login,
      'photo_url': photoUrl,
      'on_work_status': onWorkStatus,
      'role': role?.toJson(),
    };
  }
}

class Role {
  final String name;
  final String? displayName;

  Role({required this.name, this.displayName});

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      name: json['name'],
      displayName: json['display_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'display_name': displayName,
    };
  }
}
