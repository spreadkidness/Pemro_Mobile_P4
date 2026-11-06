import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isDarkMode = false;
  bool _isLoading = true;
  int _visitCount = 0;
  List<String> _favorites = [];

  User? get user => _user;
  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;
  int get visitCount => _visitCount;
  List<String> get favorites => List.unmodifiable(_favorites);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;

    _visitCount = prefs.getInt('visit_count') ?? 0;
    _visitCount++;

    await prefs.setInt('visit_count', _visitCount);

    _favorites = prefs.getStringList('favorites') ?? [];

    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');

    if (name != null && email != null) {
      _user = User(name: name, email: email);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);

    notifyListeners();
  }

  Future<String?> saveProfile({
    required String name,
    required String email,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty || cleanEmail.isEmpty) {
      return 'Nama dan email wajib diisi.';
    }

    if (RegExp(r'<[^>]*>|[<>]').hasMatch(cleanName)) {
      return 'Nama mengandung karakter berbahaya.';
    }

    final emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

    if (!emailPattern.hasMatch(cleanEmail)) {
      return 'Format email tidak valid.';
    }

    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');

    if (savedEmail != null &&
        savedEmail.toLowerCase() == cleanEmail &&
        (_user == null || _user!.email.toLowerCase() != cleanEmail)) {
      return 'Email sudah digunakan.';
    }

    await prefs.setString('user_name', cleanName);
    await prefs.setString('user_email', cleanEmail);

    _user = User(name: cleanName, email: cleanEmail);

    notifyListeners();

    return null;
  }

  Future<void> addFavorite(String item) async {
    final value = item.trim();

    if (value.isEmpty) return;

    if (_favorites.any(
      (favorite) => favorite.toLowerCase() == value.toLowerCase(),
    )) {
      return;
    }

    _favorites.add(value);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);

    notifyListeners();
  }

  Future<void> removeFavorite(String item) async {
    _favorites.remove(item);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites);

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('user_name');
    await prefs.remove('user_email');

    _user = null;
    notifyListeners();
  }
}
