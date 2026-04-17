class AppUser {
  final String uid;
  final String email;
  final String fullname;
  final String role;
  final String phone;
  final String avatar;
  final bool status;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullname,
    required this.role,
    required this.phone,
    required this.avatar,
    required this.status,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      uid: id,
      email: data["email"] ?? "",
      fullname: data["fullname"] ?? "",
      role: data["role"] ?? "CUSTOMER",
      phone: data["phone"] ?? "",
      avatar: data["avatar"] ?? "",
      status: data["status"] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "email": email,
      "fullname": fullname,
      "role": role,
      "phone": phone,
      "avatar": avatar,
      "status": status,
    };
  }
}
