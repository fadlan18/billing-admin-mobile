class AdminUser {
  final String id;
  final String email;
  final String name;
  final String role;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }
}
