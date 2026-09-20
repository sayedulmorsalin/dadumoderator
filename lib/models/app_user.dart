class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role; // 'moderator' or 'admin'

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin';
  bool get isModerator => role == 'moderator';

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'moderator',
    );
  }
}
