import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Player profile data for nickname and future profile fields
class ProfileManager extends ChangeNotifier {
  static final ProfileManager _instance = ProfileManager._internal();
  factory ProfileManager() => _instance;
  ProfileManager._internal();

  static const String _keyNickname = 'profile_nickname';

  String _nickname = '';

  String get nickname => _nickname;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _nickname = prefs.getString(_keyNickname) ?? _generateDefaultNickname();
    await prefs.setString(_keyNickname, _nickname);
    notifyListeners();
  }

  Future<void> setNickname(String value) async {
    _nickname = value.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNickname, _nickname);
    notifyListeners();
  }

  String _generateDefaultNickname() {
    final rng = Random();
    final num = 1000 + rng.nextInt(9000);
    return 'Pilot$num';
  }
}


