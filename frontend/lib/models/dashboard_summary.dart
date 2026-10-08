class DashboardSummary {
  final int totalDisasterReports;
  final int criticalCases;
  final int highPriorityCases;
  final int mediumCases;
  final int lowCases;
  final int peopleAffected;
  final int totalInjured;
  final int totalMissing;
  final int immediateHelpTotal;
  final int activeRescueTeams;
  final int availableRescueTeams;
  final int totalRescueTeams;
  final int availableShelters;
  final int totalShelters;
  final int shelterSeatsAvailable;
  final int shelterSeatsCapacity;
  final int medicalAssistanceRequired;
  final int totalMedicalRequests;
  final int ambulanceRequests;
  final int reliefResourcesCount;
  final int availableResourcesCount;
  final int lowResourcesCount;

  DashboardSummary({
    required this.totalDisasterReports,
    required this.criticalCases,
    required this.highPriorityCases,
    required this.mediumCases,
    required this.lowCases,
    required this.peopleAffected,
    required this.totalInjured,
    required this.totalMissing,
    required this.immediateHelpTotal,
    required this.activeRescueTeams,
    required this.availableRescueTeams,
    required this.totalRescueTeams,
    required this.availableShelters,
    required this.totalShelters,
    required this.shelterSeatsAvailable,
    required this.shelterSeatsCapacity,
    required this.medicalAssistanceRequired,
    required this.totalMedicalRequests,
    required this.ambulanceRequests,
    required this.reliefResourcesCount,
    required this.availableResourcesCount,
    required this.lowResourcesCount,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    int getInt(String key) => json[key] is int ? json[key] : int.tryParse(json[key]?.toString() ?? '0') ?? 0;

    return DashboardSummary(
      totalDisasterReports: getInt('total_disaster_reports'),
      criticalCases: getInt('critical_cases'),
      highPriorityCases: getInt('high_priority_cases'),
      mediumCases: getInt('medium_cases'),
      lowCases: getInt('low_cases'),
      peopleAffected: getInt('people_affected'),
      totalInjured: getInt('total_injured'),
      totalMissing: getInt('total_missing'),
      immediateHelpTotal: getInt('immediate_help_total'),
      activeRescueTeams: getInt('active_rescue_teams'),
      availableRescueTeams: getInt('available_rescue_teams'),
      totalRescueTeams: getInt('total_rescue_teams'),
      availableShelters: getInt('available_shelters'),
      totalShelters: getInt('total_shelters'),
      shelterSeatsAvailable: getInt('shelter_seats_available'),
      shelterSeatsCapacity: getInt('shelter_seats_capacity'),
      medicalAssistanceRequired: getInt('medical_assistance_required'),
      totalMedicalRequests: getInt('total_medical_requests'),
      ambulanceRequests: getInt('ambulance_requests'),
      reliefResourcesCount: getInt('relief_resources_count'),
      availableResourcesCount: getInt('available_resources_count'),
      lowResourcesCount: getInt('low_resources_count'),
    );
  }

  factory DashboardSummary.empty() {
    return DashboardSummary(
      totalDisasterReports: 0,
      criticalCases: 0,
      highPriorityCases: 0,
      mediumCases: 0,
      lowCases: 0,
      peopleAffected: 0,
      totalInjured: 0,
      totalMissing: 0,
      immediateHelpTotal: 0,
      activeRescueTeams: 0,
      availableRescueTeams: 0,
      totalRescueTeams: 0,
      availableShelters: 0,
      totalShelters: 0,
      shelterSeatsAvailable: 0,
      shelterSeatsCapacity: 0,
      medicalAssistanceRequired: 0,
      totalMedicalRequests: 0,
      ambulanceRequests: 0,
      reliefResourcesCount: 0,
      availableResourcesCount: 0,
      lowResourcesCount: 0,
    );
  }
}
