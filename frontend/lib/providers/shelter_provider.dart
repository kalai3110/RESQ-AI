import 'package:flutter/foundation.dart';
import '../models/shelter.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class ShelterProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Shelter> _shelters = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Shelter> get shelters => _shelters;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalAvailableSeats => _shelters.fold(0, (sum, s) => sum + s.available);
  int get totalCapacity => _shelters.fold(0, (sum, s) => sum + s.capacity);

  Future<void> fetchShelters({String? district, String? status}) async {
    _isLoading = true;
    notifyListeners();

    String url = ApiConstants.shelters;
    List<String> params = [];
    if (district != null && district.isNotEmpty) params.add('district=$district');
    if (status != null && status.isNotEmpty) params.add('status=$status');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final result = await _apiService.get(url);
    _isLoading = false;

    if (result['success'] == true && result['shelters'] is List) {
      _shelters = (result['shelters'] as List).map((e) => Shelter.fromJson(e)).toList();
    } else {
      _errorMessage = result['message'] ?? 'Failed to load shelters';
    }
    notifyListeners();
  }

  Future<bool> updateShelterCapacity(int shelterId, {int? capacity, int? occupied, bool? food, bool? water, bool? medical}) async {
    final Map<String, dynamic> body = {};
    if (capacity != null) body['capacity'] = capacity;
    if (occupied != null) body['occupied'] = occupied;
    if (food != null) body['food_available'] = food;
    if (water != null) body['water_available'] = water;
    if (medical != null) body['medical_available'] = medical;

    final result = await _apiService.patch(ApiConstants.shelterDetail(shelterId), body);
    if (result['success'] == true) {
      fetchShelters();
      return true;
    }
    return false;
  }
}
