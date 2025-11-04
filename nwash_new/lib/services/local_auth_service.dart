import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

import '../models/user_model.dart';

abstract class Disposable {
  void dispose();
}

class LocalAuthService implements Disposable {
  final _logger = Logger('LocalAuthService');
  static const String _userKey = 'current_user';
  static const String _tokenKey = 'auth_token';
  static const String _passwordKeyPrefix = 'user_password_';

  LocalAuthService() {
    // Constructor logic here (if any)
  }

  // Initialize the service
  Future<void> initialize() async {
    _logger.fine('Initializing LocalAuthService');
    // Any initialization code can go here
  }

  // Get current user from local storage
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        final userData = json.decode(userJson);
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Get current user error: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Authenticate with FTP server
      // final user = await _ftpService.authenticateUser(email, password);

      // if (user != null) {
      //   // Store user locally
      //   await _saveUserLocally(user);
      //   await _saveAuthToken(_generateToken(user));
      //   return user;
      // }
      return null;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Register new user
  Future<UserModel?> createUserWithEmailAndPassword(String email, String password, String name) async {
    try {
      // Create user model
      final user = UserModel(
        uid: _generateUid(),
        email: email,
        name: name,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      // Register user on FTP server
      // final success = await _ftpService.registerUser(user, password);

      // if (success) {
      //   // Store user locally
      //   await _saveUserLocally(user);
      //   await _saveAuthToken(_generateToken(user));
      //   return user;
      // }
      return null;
    } catch (e) {
      print('Create user error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userKey);
      await prefs.remove(_tokenKey);
    } catch (e) {
      _logger.severe('Sign out error', e);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel user) async {
    try {
      // Update on FTP server
      // final success = await _ftpService.updateUserProfile(user);

      // if (success) {
      //   // Update local storage
      //   await _saveUserLocally(user);
      //   return true;
      // }
      return false;
    } catch (e) {
      print('Update user profile error: $e');
      return false;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final user = await getCurrentUser();
      final token = await _getAuthToken();
      return user != null && token != null;
    } catch (e) {
      return false;
    }
  }

  // Save user credentials for offline use
  Future<bool> saveOfflineCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_passwordKeyPrefix$email';
      return await prefs.setString(key, _hashPassword(password));
    } catch (e) {
      _logger.severe('Failed to save offline credentials', e);
      return false;
    }
  }

  // Save user data locally
  Future<bool> saveUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      return await prefs.setString(_userKey, userJson);
    } catch (e) {
      _logger.severe('Failed to save user locally', e);
      return false;
    }
  }

  // Save password securely
  Future<bool> savePassword(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_passwordKeyPrefix$email';
      return await prefs.setString(key, _hashPassword(password));
    } catch (e) {
      _logger.severe('Failed to save password', e);
      return false;
    }
  }

  // Check offline credentials
  Future<bool> checkOfflineCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_passwordKeyPrefix$email';
      final storedHash = prefs.getString(key);
      return storedHash == _hashPassword(password);
    } catch (e) {
      _logger.severe('Failed to check offline credentials', e);
      return false;
    }
  }

  // Helper method to hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // Helper method to generate token
  String _generateToken(UserModel user) {
    final time = DateTime.now().millisecondsSinceEpoch.toString();
    final input = '${user.uid}$time';
    return md5.convert(utf8.encode(input)).toString();
  }

  String _generateUid() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    return 'user_${timestamp}_$random';
  }

  Future<void> _saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      print('Save auth token error: $e');
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _logger.fine('Disposing LocalAuthService');
    // Clean up any resources if needed
  }
} 