class UserModel {
  final int id;
  final String name;
  final String email;
  final String role; // 'citizen', 'rescue', 'admin'
  final String? phone;
  final String? firebaseUid;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.firebaseUid,
    this.createdAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isRescueWorker => role.toLowerCase() == 'rescue' || role.toLowerCase() == 'admin';
  bool get isCitizen => role.toLowerCase() == 'citizen';

  String get roleDisplay {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Disaster Response Commander';
      case 'rescue':
        return 'Rescue Response Officer';
      default:
        return 'Citizen Reporter';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'citizen',
      phone: json['phone'],
      firebaseUid: json['firebase_uid'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'firebase_uid': firebaseUid,
      'created_at': createdAt,
    };
  }
}
