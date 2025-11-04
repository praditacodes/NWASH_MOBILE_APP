import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import '../services/local_auth_service.dart';
import '../services/connectivity_service.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  late final LocalAuthService _localAuthService;
  final ConnectivityService _connectivityService = ConnectivityService();
  final ApiService _apiService = ApiService();
  final Logger _logger = Logger('AuthProvider');

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isOnline = false;

  AuthProvider() : _user = null, _isLoading = true, _isOnline = false {
    _localAuthService = LocalAuthService();
    
    _checkInitialConnectivity();
    _initConnectivityListener();
    _initialize(); // Initialize auth state
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isOnline => _isOnline;
  LocalAuthService get authService => _localAuthService;

  Future<void> signIn(BuildContext context, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _connectivityService.checkConnectivity();
      _isOnline = _connectivityService.isOnline(result);

      if (!_isOnline) {
        // Try offline login
        final ok = await _localAuthService.checkOfflineCredentials(email, password);
        if (ok) {
          // Restore user from local storage
          final user = await _localAuthService.getCurrentUser();
          if (user != null && user.email == email) {
            _user = user;
            // Ensure user email is always saved for offline session access
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_email', email);
            print('Offline login successful for: $email');
            return;
          } else {
            throw Exception('No offline data for this user. Please login online first.');
          }
        } else {
          throw Exception('Invalid credentials for offline login.');
        }
      }

      final loginData = await _apiService.login(email, password);
      final now = DateTime.now();
      if (loginData['access'] != null) {
        // Optionally fetch user profile if available
        Map<String, dynamic>? userData;
        try {
          userData = await _apiService.getUserData();
        } catch (_) {}

        _user = userData != null
            ? UserModel.fromJson(userData)
            : UserModel(
                uid: await _apiService.getToken() ?? 'token',
                email: email,
                createdAt: now,
                lastLoginAt: now,
              );

        print('Authentication successful for: $email');
        // Save password for offline login
        await _localAuthService.savePassword(email, password);
        // Save user locally for offline login
        await _localAuthService.saveUserLocally(_user!);
      } else {
        throw Exception('Login failed: no access token');
      }
      print('isAuthenticated: $isAuthenticated');
    } catch (e) {
      _user = null;
      _error = e.toString();
      print('AuthProvider signIn error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final connectivityResult = await _connectivityService.checkConnectivity();
      _isOnline = _connectivityService.isOnline(connectivityResult);

      if (!_isOnline) {
        throw Exception('Internet connection required for registration');
      }

      final response = await _apiService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );

      if (response['error'] == null) {
        // Registration successful
        _user = UserModel(
          id: response['id']?.toString() ?? '0',
          email: email,
          name: name,
          phone: phone,
          uid: response['uid']?.toString() ?? '',
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        
        // Save user data locally
        try {
          await _localAuthService.saveUserLocally(_user!);
          await _localAuthService.savePassword(email, password);
        } catch (e) {
          _logger.warning('Failed to save user data locally: $e');
        }
        
        return true;
      } else {
        _error = response['error']?.toString() ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      _user = null;
      _error = e.toString();
      print('Registration failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.logout();
      _user = null;
      print('User signed out successfully');
    } catch (e) {
      _error = e.toString();
      print('Sign out failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _connectivityService.checkConnectivity();
      _isOnline = _connectivityService.isOnline(result);

      if (!_isOnline) {
        throw Exception('Internet connection required for profile update');
      }

      final success = await _localAuthService.updateUserProfile(user);
      
      if (success) {
        _user = user;
        print('Profile updated successfully');
      } else {
        throw Exception('Failed to update profile');
      }

    } catch (e) {
      _error = e.toString();
      print('Profile update failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _connectivityService.checkConnectivity();
      _isOnline = _connectivityService.isOnline(result);

      if (!_isOnline) {
        throw Exception('Internet connection required for password reset');
      }

      // For FTP-based system, password reset would need to be implemented
      // This could involve sending an email with a reset link or generating a temporary password
      throw Exception('Password reset not implemented for FTP-based system');

    } catch (e) {
      _error = e.toString();
      print('Password reset failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivityService.checkConnectivity();
    _isOnline = _connectivityService.isOnline(result);
    notifyListeners();
  }

  // Listen for connectivity changes
  void _initConnectivityListener() {
    _connectivityService.onConnectivityChanged.listen((ConnectivityResult result) {
      final currentlyOnline = _connectivityService.isOnline(result);
      if (currentlyOnline != _isOnline) {
        _isOnline = currentlyOnline;
        notifyListeners();
      }
    });
  }

  // Initialize any required services and check authentication status on startup
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Initialize local auth if it has an initialize method
      try {
        await _localAuthService.initialize();
      } catch (e) {
        _logger.warning('Local auth initialization warning: $e');
      }
      
      // Check if user is already logged in
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      
      if (token != null) {
        try {
          final userData = await _apiService.getUserData();
          if (userData != null && userData is Map<String, dynamic>) {
            _user = UserModel.fromJson(userData);
          }
        } catch (e) {
          _logger.warning('Failed to get user data: $e');
          // Clear invalid token
          await prefs.remove('access_token');
        }
      }
    } catch (e) {
      _logger.severe('Auth initialization error', e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Dispose
  @override
  void dispose() {
    // Only call dispose if the method exists
    if (_localAuthService is Disposable) {
      (_localAuthService as Disposable).dispose();
    }
    super.dispose();
  }
} 