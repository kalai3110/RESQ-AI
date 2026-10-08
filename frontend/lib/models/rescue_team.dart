class RescueTeam {
  final int id;
  final String teamName;
  final String leaderName;
  final String contact;
  final String specialization;
  final int membersCount;
  final int? assignedReportId;
  final Map<String, dynamic>? assignedDisaster;
  final String status; // 'Available', 'Assigned', 'Preparing', 'On the Way', 'Reached', 'Completed'
  final String currentLocation;
  final String? updatedAt;

  RescueTeam({
    required this.id,
    required this.teamName,
    required this.leaderName,
    required this.contact,
    required this.specialization,
    required this.membersCount,
    this.assignedReportId,
    this.assignedDisaster,
    required this.status,
    required this.currentLocation,
    this.updatedAt,
  });

  bool get isAvailable => status.toLowerCase() == 'available';
  bool get isActive => !isAvailable;

  int get statusStep {
    switch (status) {
      case 'Assigned':
        return 1;
      case 'Preparing':
        return 2;
      case 'On the Way':
        return 3;
      case 'Reached':
        return 4;
      case 'Completed':
        return 5;
      default:
        return 0;
    }
  }

  factory RescueTeam.fromJson(Map<String, dynamic> json) {
    return RescueTeam(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      teamName: json['team_name'] ?? 'Rescue Team',
      leaderName: json['leader_name'] ?? 'Team Leader',
      contact: json['contact'] ?? '',
      specialization: json['specialization'] ?? 'General Response',
      membersCount: json['members_count'] is int ? json['members_count'] : int.tryParse(json['members_count'].toString()) ?? 8,
      assignedReportId: json['assigned_report_id'],
      assignedDisaster: json['assigned_disaster'] is Map ? Map<String, dynamic>.from(json['assigned_disaster']) : null,
      status: json['status'] ?? 'Available',
      currentLocation: json['current_location'] ?? 'Base',
      updatedAt: json['updated_at'],
    );
  }
}
