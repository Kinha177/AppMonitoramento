import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../models/user_model.dart';

class AuthService {
  final AppDatabase _db = AppDatabase.instance;

  Future<User?> register(String email, String password) async {
    final existingUser = await _db.getUserByEmail(email);
    if (existingUser != null) {
      return null;
    }

    final user = User(email: email, password: password);
    final id = await _db.createUser(user);
    return User(id: id, email: email, password: password);
  }

  Future<User?> login(String email, String password) async {
    final user = await _db.getUserByEmail(email);
    if (user == null || user.password != password) {
      return null;
    }
    return user;
  }

  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', userId);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
  }
}
