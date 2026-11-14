// lib/models/user_model.dart
class UserModel {
  final int    userId;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final String token;

  const UserModel({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> j, String token) {
    return UserModel(
      userId:   j['user_id']   as int,
      username: j['username']  as String,
      fullName: j['full_name'] as String,
      email:    j['email']     as String,
      role:     j['role']      as String,
      token:    token,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id':   userId,
    'username':  username,
    'full_name': fullName,
    'email':     email,
    'role':      role,
    'token':     token,
  };

  String get firstName => fullName.trim().split(' ').first;

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'ST';
  }
}
