class EmployeeModel {
  final String userId;
  final String area;
  final bool isAvailable;
  final int rating;
  final String role;
  final String fullname;

  EmployeeModel({
    required this.userId,
    required this.area,
    required this.isAvailable,
    required this.rating,
    required this.role,
    required this.fullname,
  });

  factory EmployeeModel.fromDoc(String id, Map<String, dynamic> data) {
    return EmployeeModel(
      userId: id,
      area: data["area"] ?? "",
      isAvailable: data["isAvailable"] ?? true,
      rating: data["rating"] ?? 0,
      role: data["role"] ?? "",
      fullname: data["fullname"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "area": area,
      "isAvailable": isAvailable,
      "rating": rating,
      "role": role,
      "fullname": fullname,
    };
  }
}
