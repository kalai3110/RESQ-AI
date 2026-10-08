import 'package:flutter/foundation.dart';
import '../models/medical_request.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class MedicalProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<MedicalRequest> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MedicalRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<MedicalRequest> get pendingRequests => _requests.where((r) => r.status != 'Completed').toList();
  int get totalInjuredPending => pendingRequests.fold(0, (sum, r) => sum + r.injuredCount);

  Future<void> fetchRequests({String? status}) async {
    _isLoading = true;
    notifyListeners();

    String url = ApiConstants.medicalRequests;
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }

    final result = await _apiService.get(url);
    _isLoading = false;

    if (result['success'] == true && result['medical_requests'] is List) {
      _requests = (result['medical_requests'] as List).map((e) => MedicalRequest.fromJson(e)).toList();
    } else {
      _errorMessage = result['message'] ?? 'Failed to load medical requests';
    }
    notifyListeners();
  }

  Future<bool> updateMedicalStatus(int reqId, String status, {String? hospital, int? ambulances}) async {
    final result = await _apiService.patch(ApiConstants.updateMedicalStatus(reqId), {
      'status': status,
      if (hospital != null) 'assigned_hospital': hospital,
      if (ambulances != null) 'ambulances_dispatched': ambulances,
    });

    if (result['success'] == true) {
      fetchRequests();
      return true;
    }
    return false;
  }
}
