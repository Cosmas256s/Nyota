// lib/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class StorageService {
  static const String _rewardImagesKey = 'reward_images';
  static const String _activitySchedulesKey = 'activity_schedules';
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  // Cache
  Map<String, String?> _rewardImagesCache = {};
  Map<String, List<Map<String, dynamic>>> _activitySchedulesCache = {};
  final Map<String, User> _usersCache = {};

  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // ───── FIXED: nullable + safe ─────
  SharedPreferences? _prefs;

  /// Initialize the storage service (call this first!)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUsersFromStorage();
  }

  // ───── REWARD IMAGES ─────
  Future<void> saveRewardImages(Map<String, String?> rewardImages) async {
    final rewardImagesJson = jsonEncode(rewardImages);
    await _prefs!.setString(_rewardImagesKey, rewardImagesJson);
    _rewardImagesCache = Map<String, String?>.from(rewardImages);
  }

  Future<Map<String, String?>> loadRewardImages() async {
    final rewardImagesJsonStr = _prefs!.getString(_rewardImagesKey);
    if (rewardImagesJsonStr == null) return {};
    final decoded = jsonDecode(rewardImagesJsonStr) as Map<String, dynamic>;
    _rewardImagesCache = decoded.map((k, v) => MapEntry(k, v as String?));
    return _rewardImagesCache;
  }

  // ───── ACTIVITY SCHEDULES ─────
  Future<void> saveActivitySchedules(Map<String, List<Map<String, dynamic>>> schedules) async {
    final schedulesJson = jsonEncode(schedules);
    await _prefs!.setString(_activitySchedulesKey, schedulesJson);
    _activitySchedulesCache = Map<String, List<Map<String, dynamic>>>.from(schedules);
  }

  Future<Map<String, List<Map<String, dynamic>>>> loadActivitySchedules() async {
    final schedulesJsonStr = _prefs!.getString(_activitySchedulesKey);
    if (schedulesJsonStr == null) {
      return {
        'Shapes': [],
        'Counting': [],
        'Basic Math': [],
        'Advanced Math': [],
      };
    }
    final decoded = jsonDecode(schedulesJsonStr) as Map<String, dynamic>;
    final result = <String, List<Map<String, dynamic>>>{};
    decoded.forEach((k, v) {
      result[k] = (v as List).map((item) => Map<String, dynamic>.from(item)).toList();
    });
    _activitySchedulesCache = result;
    return result;
  }

  // ───── USERS ─────
  Future<void> _loadUsersFromStorage() async {
    final usersJson = _prefs!.getStringList(_usersKey) ?? [];
    _usersCache.clear();

    for (final userJsonStr in usersJson) {
      try {
        final userJson = jsonDecode(userJsonStr) as Map<String, dynamic>;
        final user = User.fromJson(userJson);
        _usersCache[user.id] = user;
      } catch (e) {
        print('Error loading user from storage: $e');
      }
    }
  }

  Future<User?> getUser(String id) async => _usersCache[id];

  Future<User?> getUserByUsername(String username) async {
    try {
      return _usersCache.values.firstWhere((user) => user.username == username);
    } catch (e) {
      return null;
    }
  }

  Future<User> createUser(InsertUser insertUser) async {
    final user = User(
      id: _generateUUID(),
      username: insertUser.username,
    );
    _usersCache[user.id] = user;
    await _saveUsersToStorage();
    return user;
  }

  Future<void> saveCurrentUser(User user) async {
    await _prefs!.setString(_currentUserKey, jsonEncode(user.toJson()));
  }

  Future<User?> getCurrentUser() async {
    final userJsonStr = _prefs!.getString(_currentUserKey);
    if (userJsonStr == null) return null;
    try {
      final userJson = jsonDecode(userJsonStr) as Map<String, dynamic>;
      return User.fromJson(userJson);
    } catch (e) {
      print('Error loading current user: $e');
      return null;
    }
  }

  Future<void> clearCurrentUser() async {
    await _prefs!.remove(_currentUserKey);
  }

  Future<void> _saveUsersToStorage() async {
    final usersJson = _usersCache.values
        .map((user) => jsonEncode(user.toJson()))
        .toList();
    await _prefs!.setStringList(_usersKey, usersJson);
  }

  String _generateUUID() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_usersCache.length}';
  }

  Future<void> clearAll() async {
    _usersCache.clear();
    await _prefs!.clear();
  }
}