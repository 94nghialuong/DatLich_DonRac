class EmployeeModel {
  final String id;
  final String userId;
  final String area;
  final bool isAvailable;
  final int rating;
  final String role;

  EmployeeModel({
    required this.id,
    required this.userId,
    required this.area,
    required this.isAvailable,
    required this.rating,
    required this.role,
  });

  factory EmployeeModel.fromDoc(String id, Map<String, dynamic> data) {
    return EmployeeModel(
      id: id,
      userId: data["userId"] ?? "",
      area: data["area"] ?? "",
      isAvailable: data["isAvailable"] ?? true,
      rating: (data["rating"] ?? 0) as int,
      role: data["role"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "area": area,
      "isAvailable": isAvailable,
      "rating": rating,
      "role": role,
    };
  }
}
