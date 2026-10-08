import 'package:flutter/foundation.dart';
import '../models/relief_resource.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class ResourceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ReliefResource> _resources = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReliefResource> get resources => _resources;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchResources({String? category, String? status}) async {
    _isLoading = true;
    notifyListeners();

    String url = ApiConstants.reliefResources;
    List<String> params = [];
    if (category != null && category.isNotEmpty) params.add('category=$category');
    if (status != null && status.isNotEmpty) params.add('status=$status');

    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    final result = await _apiService.get(url);
    _isLoading = false;

    if (result['success'] == true && result['resources'] is List) {
      _resources = (result['resources'] as List).map((e) => ReliefResource.fromJson(e)).toList();
    } else {
      _errorMessage = result['message'] ?? 'Failed to load relief resources';
    }
    notifyListeners();
  }

  Future<bool> updateResource(int resourceId, int quantity, {String? location}) async {
    final result = await _apiService.patch(ApiConstants.updateResource(resourceId), {
      'quantity': quantity,
      if (location != null) 'location': location,
    });

    if (result['success'] == true) {
      fetchResources();
      return true;
    }
    return false;
  }
}
