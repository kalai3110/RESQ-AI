import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/disaster_report.dart';
import '../models/ai_prediction.dart';
import '../models/dashboard_summary.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class DisasterProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  DashboardSummary _summary = DashboardSummary.empty();
  List<DisasterReport> _reports = [];
  List<DisasterReport> _myReports = [];
  List<Map<String, dynamic>> _mapMarkers = [];
  List<Map<String, dynamic>> _mapShelters = [];
  DisasterReport? _currentReport;
  AIPrediction? _lastPrediction;
  
  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isPredicting = false;
  String? _errorMessage;

  DashboardSummary get summary => _summary;
  List<DisasterReport> get reports => _reports;
  List<DisasterReport> get myReports => _myReports;
  List<Map<String, dynamic>> get mapMarkers => _mapMarkers;
  List<Map<String, dynamic>> get mapShelters => _mapShelters;
  DisasterReport? get currentReport => _currentReport;
  AIPrediction? get lastPrediction => _lastPrediction;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isPredicting => _isPredicting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDashboardSummary() async {
    final result = await _apiService.get(ApiConstants.dashboardSummary);
    if (result['success'] == true && result['summary'] != null) {
      _summary = DashboardSummary.fromJson(result['summary']);
      notifyListeners();
    }
  }

  Future<AIPrediction?> predictSeverity({
    required String disasterType,
    required int peopleAffected,
    required int injured,
    required int missing,
    required int immediateHelpRequired,
    required String damageLevel,
    bool infrastructureDamage = false,
    bool propertyDamage = false,
  }) async {
    _isPredicting = true;
    notifyListeners();

    final result = await _apiService.post(ApiConstants.predictSeverity, {
      'disaster_type': disasterType,
      'people_affected': peopleAffected,
      'injured': injured,
      'missing': missing,
      'immediate_help_required': immediateHelpRequired,
      'damage_level': damageLevel,
      'infrastructure_damage': infrastructureDamage ? 1 : 0,
      'property_damage': propertyDamage ? 1 : 0,
    });

    _isPredicting = false;

    if (result['success'] == true && result['prediction'] != null) {
      _lastPrediction = AIPrediction.fromJson(result['prediction']);
      notifyListeners();
      return _lastPrediction;
    } else {
      _errorMessage = result['message'] ?? 'Failed to get AI prediction';
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>> submitReport({
    required int userId,
    required String disasterType,
    required String district,
    required String area,
    required String address,
    required int peopleAffected,
    required int injured,
    required int missing,
    required int immediateHelpRequired,
    required bool propertyDamage,
    required bool infrastructureDamage,
    required String damageLevel,
    String? description,
    File? imageFile,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final fields = {
      'user_id': userId.toString(),
      'disaster_type': disasterType,
      'district': district.trim(),
      'area': area.trim(),
      'address': address.trim(),
      'people_affected': peopleAffected.toString(),
      'injured': injured.toString(),
      'missing': missing.toString(),
      'immediate_help_required': immediateHelpRequired.toString(),
      'property_damage': propertyDamage.toString(),
      'infrastructure_damage': infrastructureDamage.toString(),
      'damage_level': damageLevel,
      'description': description ?? '',
    };

    final result = await _apiService.postMultipart(
      ApiConstants.submitReport,
      fields,
      imageFile: imageFile,
    );

    _isSubmitting = false;

    if (result['success'] == true) {
      // Refresh dashboard & reports
      fetchDashboardSummary();
      fetchReports();
      fetchMyReports(userId);
      notifyListeners();
      return {
        'success': true,
        'report': result['report'] != null ? DisasterReport.fromJson(result['report']) : null,
        'ai_analysis': result['ai_analysis'] != null ? AIPrediction.fromJson(result['ai_analysis']) : null,
        'assigned_team': result['assigned_team']
      };
    } else {
      _errorMessage = result['message'] ?? 'Failed to submit disaster report.';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }

  Future<void> fetchReports({String? district, String? severity, String? priority, String? status}) async {
    _isLoading = true;
    notifyListeners();

    String url = ApiConstants.reports;
    List<String> queryParams = [];
    if (district != null && district.isNotEmpty) queryParams.add('district=$district');
    if (severity != null && severity.isNotEmpty) queryParams.add('severity=$severity');
    if (priority != null && priority.isNotEmpty) queryParams.add('priority=$priority');
    if (status != null && status.isNotEmpty) queryParams.add('status=$status');

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final result = await _apiService.get(url);
    _isLoading = false;

    if (result['success'] == true && result['reports'] is List) {
      _reports = (result['reports'] as List).map((e) => DisasterReport.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> fetchMyReports(int userId) async {
    final result = await _apiService.get('${ApiConstants.myReports}?user_id=$userId');
    if (result['success'] == true && result['reports'] is List) {
      _myReports = (result['reports'] as List).map((e) => DisasterReport.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<DisasterReport?> fetchReportDetail(int reportId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _apiService.get(ApiConstants.reportDetail(reportId));
    _isLoading = false;

    if (result['success'] == true && result['report'] != null) {
      _currentReport = DisasterReport.fromJson(result['report']);
      notifyListeners();
      return _currentReport;
    }
    notifyListeners();
    return null;
  }

  Future<void> fetchMapData() async {
    final result = await _apiService.get(ApiConstants.mapDisasters);
    if (result['success'] == true) {
      if (result['disaster_markers'] is List) {
        _mapMarkers = List<Map<String, dynamic>>.from(result['disaster_markers']);
      }
      if (result['shelter_markers'] is List) {
        _mapShelters = List<Map<String, dynamic>>.from(result['shelter_markers']);
      }
      notifyListeners();
    }
  }

  Future<bool> updateReportStatus(int reportId, String newStatus) async {
    final result = await _apiService.patch(ApiConstants.updateReportStatus(reportId), {
      'status': newStatus,
    });
    if (result['success'] == true) {
      fetchReports();
      fetchDashboardSummary();
      return true;
    }
    return false;
  }

  Future<bool> overrideSeverity(int reportId, String newSeverity, {String? priority}) async {
    final result = await _apiService.patch(ApiConstants.overrideSeverity(reportId), {
      'severity': newSeverity,
      'priority': priority,
    });
    if (result['success'] == true) {
      fetchReports();
      fetchDashboardSummary();
      return true;
    }
    return false;
  }
}
