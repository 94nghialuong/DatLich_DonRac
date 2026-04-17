class ServiceModel {
  final String id;
  final String name;
  final String description;
  final String url;
  final int price;

  ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.price,
  });

  factory ServiceModel.fromDoc(String id, Map<String, dynamic> data) {
    return ServiceModel(
      id: id,
      name: data["name"] ?? "",
      description: data["description"] ?? "",
      url: data["URL"] ?? "",
      price: data["price"] ?? 0,
    );
  }
}
