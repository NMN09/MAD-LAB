class AppUser {
  final String uid;
  final String email;
  final String role; // 'user', 'admin', 'superadmin'

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isSuperAdmin => role == 'superadmin';
}
