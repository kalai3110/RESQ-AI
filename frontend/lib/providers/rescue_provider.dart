import 'package:flutter/foundation.dart';
import '../models/rescue_team.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class RescueProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<RescueTeam> _teams = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RescueTeam> get teams => _teams;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<RescueTeam> get activeTeams => _teams.where((t) => t.isActive).toList();
  List<RescueTeam> get availableTeams => _teams.where((t) => t.isAvailable).toList();

  Future<void> fetchTeams({String? status}) async {
    _isLoading = true;
    notifyListeners();

    String url = ApiConstants.rescueTeams;
    if (status != null && status.isNotEmpty) {
      url += '?status=$status';
    }

    final result = await _apiService.get(url);
    _isLoading = false;

    if (result['success'] == true && result['teams'] is List) {
      _teams = (result['teams'] as List).map((e) => RescueTeam.fromJson(e)).toList();
    } else {
      _errorMessage = result['message'] ?? 'Failed to load rescue teams';
    }
    notifyListeners();
  }

  Future<bool> updateTeamStatus(int teamId, String status, {String? currentLocation}) async {
    final result = await _apiService.patch(ApiConstants.updateTeamStatus(teamId), {
      'status': status,
      if (currentLocation != null) 'current_location': currentLocation,
    });

    if (result['success'] == true) {
      fetchTeams();
      return true;
    }
    return false;
  }

  Future<bool> assignTeam(int teamId, int reportId) async {
    final result = await _apiService.post(ApiConstants.assignRescueTeam, {
      'team_id': teamId,
      'report_id': reportId,
    });

    if (result['success'] == true) {
      fetchTeams();
      return true;
    }
    return false;
  }
}
