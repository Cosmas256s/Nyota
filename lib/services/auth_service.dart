import 'storage_service.dart';
import 'api_client.dart';
import '../models/user.dart';

/// Authentication service for managing user authentication
class AuthService {
  static final AuthService _instance = AuthService._internal();
  final StorageService _storageService = StorageService();
  final ApiClient _apiClient = ApiClient();

  User? _currentUser;

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Initialize auth service
  Future<void> init() async {
    await _storageService.init();
    _currentUser = await _storageService.getCurrentUser();
  }

  /// Register a new user
  Future<User> signup(String username, String password) async {
    // Check if user already exists
    final existingUser = await _storageService.getUserByUsername(username);
    if (existingUser != null) {
      throw Exception('Username already exists');
    }

    // Create new user
    final insertUser = InsertUser(username: username, password: password);
    final user = await _storageService.createUser(insertUser);

    // Save as current user
    _currentUser = user;
    await _storageService.saveCurrentUser(user);

    return user;
  }

  /// Login user
  Future<User> login(String username, String password) async {
    // Check credentials
    final user = await _storageService.getUserByUsername(username);
    if (user == null) {
      throw Exception('User not found');
    }

    // In a real app, you would verify the password here
    // For now, we're just checking the username
    _currentUser = user;
    await _storageService.saveCurrentUser(user);

    return user;
  }

  /// Logout user
  Future<void> logout() async {
    _currentUser = null;
    await _storageService.clearCurrentUser();
  }

  /// Get current logged-in user
  User? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;
}
