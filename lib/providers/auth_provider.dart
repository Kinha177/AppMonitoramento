import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<bool> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.register(email, password);
    _isLoading = false;

    if (user != null) {
      _currentUser = user;
      await _authService.saveUserId(user.id!);
      notifyListeners();
      return true;
    }

    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final user = await _authService.login(email, password);
    _isLoading = false;

    if (user != null) {
      _currentUser = user;
      await _authService.saveUserId(user.id!);
      notifyListeners();
      return true;
    }

    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<int?> getCurrentUserId() async {
    return await _authService.getUserId();
  }
}
