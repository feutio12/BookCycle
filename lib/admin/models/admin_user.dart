class AdminUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  factory AdminUser.fromMap(Map<String, dynamic> data, String id) {
    return AdminUser(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'admin',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? data['createdAt'].toDate()
          : DateTime.now(),
      lastLogin: data['lastLogin']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }
}