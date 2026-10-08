import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Default base URLs depending on platform
  static String getDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      // Android emulator connects to host machine via 10.0.2.2
      return 'http://10.0.2.2:5000';
    } else {
      return 'http://localhost:5000';
    }
  }

  // Active base URL (can be customized by user in Settings)
  static String baseUrl = getDefaultBaseUrl();

  // Auth Endpoints
  static String get login => '$baseUrl/api/auth/login';
  static String get googleLogin => '$baseUrl/api/auth/google-login';
  static String get register => '$baseUrl/api/auth/register';
  static String get profile => '$baseUrl/api/auth/profile';

  // Disaster Reports & ML Endpoints
  static String get predictSeverity => '$baseUrl/api/disaster/predict';
  static String get submitReport => '$baseUrl/api/disaster/report';
  static String get reports => '$baseUrl/api/disaster/reports';
  static String get myReports => '$baseUrl/api/disaster/my-reports';
  static String reportDetail(int id) => '$baseUrl/api/disaster/reports/$id';
  static String updateReportStatus(int id) => '$baseUrl/api/disaster/reports/$id/status';
  static String overrideSeverity(int id) => '$baseUrl/api/disaster/reports/$id/severity';

  // Rescue Teams Endpoints
  static String get rescueTeams => '$baseUrl/api/rescue/teams';
  static String updateTeamStatus(int id) => '$baseUrl/api/rescue/teams/$id/status';
  static String get assignRescueTeam => '$baseUrl/api/rescue/teams/assign';

  // Shelters Endpoints
  static String get shelters => '$baseUrl/api/shelters';
  static String shelterDetail(int id) => '$baseUrl/api/shelters/$id';

  // Medical Assistance Endpoints
  static String get medicalRequests => '$baseUrl/api/medical/requests';
  static String updateMedicalStatus(int id) => '$baseUrl/api/medical/requests/$id/status';

  // Relief Resources Endpoints
  static String get reliefResources => '$baseUrl/api/resources';
  static String updateResource(int id) => '$baseUrl/api/resources/$id';

  // Map Endpoints
  static String get mapDisasters => '$baseUrl/api/map/disasters';

  // Notifications Endpoints
  static String get notifications => '$baseUrl/api/notifications';
  static String markNotificationRead(int id) => '$baseUrl/api/notifications/$id/read';
  static String get markAllNotificationsRead => '$baseUrl/api/notifications/read-all';

  // Dashboard Summary Endpoint
  static String get dashboardSummary => '$baseUrl/api/dashboard/summary';

  // Static uploads image url
  static String imageUrl(String filename) => '$baseUrl/uploads/$filename';
}
