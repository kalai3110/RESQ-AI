class MedicalRequest {
  final int id;
  final int reportId;
  final String disasterType;
  final String location;
  final String severity;
  final String priority;
  final int injuredCount;
  final bool emergencyTreatmentRequired;
  final bool ambulanceRequired;
  final bool firstAidRequired;
  final bool medicalRequired;
  final String status; // 'Requested', 'Assigned', 'On the Way', 'Completed'
  final String? assignedHospital;
  final int ambulancesDispatched;
  final String? updatedAt;

  MedicalRequest({
    required this.id,
    required this.reportId,
    required this.disasterType,
    required this.location,
    required this.severity,
    required this.priority,
    required this.injuredCount,
    required this.emergencyTreatmentRequired,
    required this.ambulanceRequired,
    required this.firstAidRequired,
    required this.medicalRequired,
    required this.status,
    this.assignedHospital,
    required this.ambulancesDispatched,
    this.updatedAt,
  });

  factory MedicalRequest.fromJson(Map<String, dynamic> json) {
    return MedicalRequest(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      reportId: json['report_id'] is int ? json['report_id'] : int.tryParse(json['report_id'].toString()) ?? 0,
      disasterType: json['disaster_type'] ?? 'Emergency',
      location: json['location'] ?? '',
      severity: json['severity'] ?? 'MEDIUM',
      priority: json['priority'] ?? 'P3',
      injuredCount: json['injured_count'] is int ? json['injured_count'] : int.tryParse(json['injured_count'].toString()) ?? 0,
      emergencyTreatmentRequired: json['emergency_treatment_required'] == true || json['emergency_treatment_required'] == 1,
      ambulanceRequired: json['ambulance_required'] == true || json['ambulance_required'] == 1,
      firstAidRequired: json['first_aid_required'] == true || json['first_aid_required'] == 1,
      medicalRequired: json['medical_required'] == true || json['medical_required'] == 1,
      status: json['status'] ?? 'Requested',
      assignedHospital: json['assigned_hospital'],
      ambulancesDispatched: json['ambulances_dispatched'] is int ? json['ambulances_dispatched'] : int.tryParse(json['ambulances_dispatched'].toString()) ?? 0,
      updatedAt: json['updated_at'],
    );
  }
}
