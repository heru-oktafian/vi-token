class UserModel {
  final String id;
  final String username;
  final String name;
  final String role;
  final String status;

  UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      role: json['user_role'] ?? '',
      status: json['user_status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'user_role': role,
      'user_status': status,
    };
  }
}
