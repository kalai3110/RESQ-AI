class ReliefResource {
  final int id;
  final String resourceName;
  final String category;
  final int quantity;
  final String unit;
  final String displayQuantity;
  final String status; // 'Available', 'Limited', 'Low', 'Out of Stock'
  final String location;
  final String? updatedAt;

  ReliefResource({
    required this.id,
    required this.resourceName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.displayQuantity,
    required this.status,
    required this.location,
    this.updatedAt,
  });

  bool get isLow => status == 'Low' || status == 'Out of Stock';

  factory ReliefResource.fromJson(Map<String, dynamic> json) {
    int qty = json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity'].toString()) ?? 0;
    String u = json['unit'] ?? 'units';
    return ReliefResource(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      resourceName: json['resource_name'] ?? 'Resource',
      category: json['category'] ?? 'General Supplies',
      quantity: qty,
      unit: u,
      displayQuantity: json['display_quantity'] ?? '$qty $u',
      status: json['status'] ?? 'Available',
      location: json['location'] ?? 'Depot',
      updatedAt: json['updated_at'],
    );
  }
}
