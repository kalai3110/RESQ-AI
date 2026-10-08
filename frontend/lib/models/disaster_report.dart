import 'rescue_team.dart';
import 'shelter.dart';
import 'medical_request.dart';

class DisasterReport {
  final int id;
  final String reportId; // e.g. "DR-1025"
  final int userId;
  final String reporterName;
  final String disasterType;
  final String district;
  final String area;
  final String address;
  final String locationDisplay;
  final double? latitude;
  final double? longitude;
  final int peopleAffected;
  final int injured;
  final int missing;
  final int immediateHelpRequired;
  final bool propertyDamage;
  final bool infrastructureDamage;
  final String damageLevel;
  final String? description;
  final String? imageUrl;
  final String severity; // 'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'
  final String priority; // 'P1', 'P2', 'P3', 'P4'
  final String status;   // 'Reported', 'Verified', 'Rescue in Progress', 'Resolved'
  final List<String> assignedTeams;
  final List<RescueTeam>? rescueTeamsList;
  final List<Shelter>? districtShelters;
  final List<MedicalRequest>? medicalRequests;
  final String? createdAt;
  final String? updatedAt;

  DisasterReport({
    required this.id,
    required this.reportId,
    required this.userId,
    required this.reporterName,
    required this.disasterType,
    required this.district,
    required this.area,
    required this.address,
    required this.locationDisplay,
    this.latitude,
    this.longitude,
    required this.peopleAffected,
    required this.injured,
    required this.missing,
    required this.immediateHelpRequired,
    required this.propertyDamage,
    required this.infrastructureDamage,
    required this.damageLevel,
    this.description,
    this.imageUrl,
    required this.severity,
    required this.priority,
    required this.status,
    this.assignedTeams = const [],
    this.rescueTeamsList,
    this.districtShelters,
    this.medicalRequests,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCritical => severity.toUpperCase() == 'CRITICAL' || priority == 'P1';
  bool get isHighPriority => priority == 'P1' || priority == 'P2';

  factory DisasterReport.fromJson(Map<String, dynamic> json) {
    List<RescueTeam>? teams;
    if (json['rescue_teams'] is List) {
      teams = (json['rescue_teams'] as List).map((e) => RescueTeam.fromJson(e)).toList();
    }

    List<Shelter>? shelters;
    if (json['district_shelters'] is List) {
      shelters = (json['district_shelters'] as List).map((e) => Shelter.fromJson(e)).toList();
    }

    List<MedicalRequest>? medReqs;
    if (json['medical_requests'] is List) {
      medReqs = (json['medical_requests'] as List).map((e) => MedicalRequest.fromJson(e)).toList();
    }

    return DisasterReport(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      reportId: json['report_id'] ?? 'DR-${json['id']}',
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      reporterName: json['reporter_name'] ?? 'Citizen',
      disasterType: json['disaster_type'] ?? 'Disaster',
      district: json['district'] ?? '',
      area: json['area'] ?? '',
      address: json['address'] ?? '',
      locationDisplay: json['location_display'] ?? '${json['area']}, ${json['district']}',
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      peopleAffected: json['people_affected'] is int ? json['people_affected'] : int.tryParse(json['people_affected'].toString()) ?? 0,
      injured: json['injured'] is int ? json['injured'] : int.tryParse(json['injured'].toString()) ?? 0,
      missing: json['missing'] is int ? json['missing'] : int.tryParse(json['missing'].toString()) ?? 0,
      immediateHelpRequired: json['immediate_help_required'] is int ? json['immediate_help_required'] : int.tryParse(json['immediate_help_required'].toString()) ?? 0,
      propertyDamage: json['property_damage'] == true || json['property_damage'] == 1,
      infrastructureDamage: json['infrastructure_damage'] == true || json['infrastructure_damage'] == 1,
      damageLevel: json['damage_level'] ?? 'Medium',
      description: json['description'],
      imageUrl: json['image_url'],
      severity: (json['severity'] ?? 'MEDIUM').toString().toUpperCase(),
      priority: json['priority'] ?? 'P3',
      status: json['status'] ?? 'Reported',
      assignedTeams: (json['assigned_teams'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      rescueTeamsList: teams,
      districtShelters: shelters,
      medicalRequests: medReqs,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
