class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'user', 'admin', 'superadmin'
  final String department;
  final String photoUrl;

  AppUser({
    required this.uid,
    required this.email,
    this.name = '',
    required this.role,
    this.department = '',
    this.photoUrl = '',
  });

  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isSuperAdmin => role == 'superadmin';

  String get displayName => name.isNotEmpty ? name : email.split('@').first;
}
