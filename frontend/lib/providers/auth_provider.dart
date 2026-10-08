import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isRescueWorker => _currentUser?.isRescueWorker ?? false;

  AuthProvider() {
    _loadPersistedUser();
  }

  Future<void> _loadPersistedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('saved_user');
    _token = prefs.getString('saved_token');

    if (userJson != null && _token != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        _apiService.setAuthToken(_token);
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading saved user: $e');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.post(ApiConstants.login, {
      'email': email.trim(),
      'password': password,
    });

    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _currentUser = UserModel.fromJson(result['user']);
      _token = result['token']?.toString() ?? 'session-token';
      _apiService.setAuthToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setString('saved_token', _token!);

      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Invalid email or password.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> continueWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Emulates Google Sign-In with real backend authentication verification
    final result = await _apiService.post(ApiConstants.googleLogin, {
      'email': 'priya.sharma@gmail.com',
      'name': 'Priya Sharma (Google User)',
      'firebase_uid': 'firebase-google-auth-9872',
      'role': 'citizen'
    });

    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _currentUser = UserModel.fromJson(result['user']);
      _token = result['token']?.toString() ?? 'google-token';
      _apiService.setAuthToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setString('saved_token', _token!);

      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Google authentication failed or was cancelled.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _apiService.post(ApiConstants.register, {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'role': role.toLowerCase(),
      'phone': phone?.trim(),
    });

    _isLoading = false;

    if (result['success'] == true && result['user'] != null) {
      _currentUser = UserModel.fromJson(result['user']);
      _token = result['token']?.toString() ?? 'reg-token';
      _apiService.setAuthToken(_token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user', jsonEncode(_currentUser!.toJson()));
      await prefs.setString('saved_token', _token!);

      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Registration failed.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _token = null;
    _apiService.setAuthToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user');
    await prefs.remove('saved_token');
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
