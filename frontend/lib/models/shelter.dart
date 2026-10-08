class Shelter {
  final int id;
  final String shelterName;
  final String location;
  final String district;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int capacity;
  final int occupied;
  final int available;
  final bool foodAvailable;
  final bool waterAvailable;
  final bool medicalAvailable;
  final String status; // 'Available', 'Limited', 'Full'
  final String? contactPerson;
  final String? contactPhone;
  final double occupancyPercentage;
  final String? updatedAt;

  Shelter({
    required this.id,
    required this.shelterName,
    required this.location,
    required this.district,
    this.address,
    this.latitude,
    this.longitude,
    required this.capacity,
    required this.occupied,
    required this.available,
    required this.foodAvailable,
    required this.waterAvailable,
    required this.medicalAvailable,
    required this.status,
    this.contactPerson,
    this.contactPhone,
    required this.occupancyPercentage,
    this.updatedAt,
  });

  bool get isFull => status.toLowerCase() == 'full' || available <= 0;

  factory Shelter.fromJson(Map<String, dynamic> json) {
    int cap = json['capacity'] is int ? json['capacity'] : int.tryParse(json['capacity'].toString()) ?? 100;
    int occ = json['occupied'] is int ? json['occupied'] : int.tryParse(json['occupied'].toString()) ?? 0;
    int avail = json['available'] is int ? json['available'] : int.tryParse(json['available'].toString()) ?? (cap - occ);

    return Shelter(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      shelterName: json['shelter_name'] ?? 'Relief Shelter',
      location: json['location'] ?? '',
      district: json['district'] ?? '',
      address: json['address'],
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      capacity: cap,
      occupied: occ,
      available: avail,
      foodAvailable: json['food_available'] == true || json['food_available'] == 1,
      waterAvailable: json['water_available'] == true || json['water_available'] == 1,
      medicalAvailable: json['medical_available'] == true || json['medical_available'] == 1,
      status: json['status'] ?? 'Available',
      contactPerson: json['contact_person'],
      contactPhone: json['contact_phone'],
      occupancyPercentage: (json['occupancy_percentage'] is num) ? (json['occupancy_percentage'] as num).toDouble() : (cap > 0 ? (occ / cap * 100) : 0),
      updatedAt: json['updated_at'],
    );
  }
}
