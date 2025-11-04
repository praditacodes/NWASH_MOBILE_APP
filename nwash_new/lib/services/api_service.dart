import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:nwash_new/config/api_config.dart';

/// A service class that handles all API calls
class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Logger for debugging
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
    ),
  );

  // HTTP client
  final http.Client _client = http.Client();
  
  // Authentication state
  String? _authToken;
  String? _refreshToken;
  late SharedPreferences _prefs;
  
  // Headers
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Initialize the service
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _authToken = _prefs.getString('access_token');
      _refreshToken = _prefs.getString('refresh_token');
      
      if (_authToken != null) {
        _headers['Authorization'] = 'Bearer $_authToken';
      }
    } catch (e) {
      _logger.e('Failed to initialize API service', error: e);
      rethrow;
    }
  }

  // Get headers with auth token
  Map<String, String> get headers => Map.from(_headers);

  // Check if user is authenticated
  bool get isAuthenticated => _authToken?.isNotEmpty == true;

  // Handle API errors
  String _handleError(dynamic error, [StackTrace? stackTrace]) {
    _logger.e('API Error:', error: error, stackTrace: stackTrace);
    
    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    } else if (error is TimeoutException) {
      return 'Request timed out. The server is taking too long to respond.';
    } else if (error is FormatException) {
      return 'Invalid server response format. Please try again later.';
    } else if (error is http.ClientException) {
      if (error.message.contains('Connection refused')) {
        return 'Could not connect to the server. Please check if the server is running.';
      }
      return 'Network error: ${error.message}';
    } else if (error is Map && error['error'] != null) {
      return error['error'].toString();
    } else if (error is String) {
      return error;
    } else {
      return 'An unexpected error occurred: ${error.toString()}';
    }
  }

  // Login and get token (Django SimpleJWT expects JSON {username, password})
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _logger.i('Attempting login for user: $email');
      
      // Log the request details
      _logger.i('Sending login request to: ${ApiConfig.baseUrl}${ApiConfig.login}');
      _logger.i('Using username: ${email.trim()}');
      
      // Django SimpleJWT: send JSON payload
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': email.trim(),
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _logger.e('Login request timed out');
          throw TimeoutException('Connection timeout. Please check your internet connection.');
        },
      );
      
      _logger.i('Login response status: ${response.statusCode}');
      _logger.i('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data['access'] != null) {
          _logger.i('Login successful, saving tokens');
          await _saveAuthData(
            accessToken: data['access'],
            refreshToken: data['refresh'] ?? '',
            email: email,
          );
          
          // Update auth headers
          _authToken = data['access'];
          _refreshToken = data['refresh'] ?? '';
          _headers['Authorization'] = 'Bearer ${data['access']}';
          
          _logger.i('Tokens saved successfully');
          return data;
        } else {
          _logger.w('No access token received in login response');
          throw Exception('No access token received');
        }
      } else {
        // Handle error response
        String errorMessage = 'Login failed with status: ${response.statusCode}';
        try {
          final errorResponse = jsonDecode(utf8.decode(response.bodyBytes));
          _logger.e('Login failed with error: $errorResponse');
          
          if (errorResponse is Map && errorResponse.containsKey('username')) {
            errorMessage = errorResponse['username'][0] ?? errorMessage;
          } else if (errorResponse is Map && errorResponse.containsKey('detail')) {
            errorMessage = errorResponse['detail'];
          } else {
            errorMessage = errorResponse.toString();
          }
        } catch (e) {
          _logger.e('Failed to parse error response: $e');
        }
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      _logger.e('Network error during login: $e');
      throw Exception('No internet connection. Please check your network settings.');
    } on TimeoutException catch (e) {
      _logger.e('Login timeout: $e');
      rethrow;
    } on FormatException catch (e) {
      _logger.e('Invalid response format: $e');
      throw Exception('Invalid server response. Please try again.');
    } catch (e) {
      _logger.e('Login error: $e');
      rethrow;
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      _logger.i('Attempting to register new user: $email');
      
      // Generate a username from email (remove @ and everything after it)
      final username = email.split('@')[0];
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'name': name,
          'phone': phone,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _logger.e('Registration request timed out');
          throw TimeoutException('Registration timed out. Please try again.');
        },
      );

      _logger.d('Registration response status: ${response.statusCode}');
      _logger.d('Registration response body: ${response.body}');

      final data = _handleResponse(response);
      
      // Auto-login after successful registration
      if (response.statusCode == 201) {
        _logger.i('Registration successful, attempting auto-login');
        try {
          // Use the username from the response if available, otherwise generate from email
          final username = data['username'] ?? email.split('@')[0];
          
          // Login with username only (not email)
          final loginResponse = await http.post(
            Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'username': username,  // Only username, no email
              'password': password,
            }),
          );
          
          final loginData = _handleResponse(loginResponse);
          
          // Save tokens if login was successful
          if (loginData['access'] != null) {
            await _saveAuthData(
              accessToken: loginData['access'],
              refreshToken: loginData['refresh'] ?? '',
              email: email,
            );
            _logger.i('Auto-login after registration successful');
          } else {
            _logger.w('Auto-login succeeded but no access token received');
          }
        } catch (e) {
          _logger.e('Auto-login after registration failed: $e');
          // Don't fail the registration just because auto-login failed
          // The user can still log in manually
        }
      } else {
        _logger.w('Unexpected status code during registration: ${response.statusCode}');
      }
      
      return data;
    } on SocketException catch (e) {
      _logger.e('Network error during registration: $e');
      throw Exception('No internet connection. Please check your network settings.');
    } on TimeoutException {
      _logger.e('Registration request timed out');
      throw TimeoutException('Registration timed out. Please try again.');
    } on FormatException catch (e) {
      _logger.e('Invalid response format during registration: $e');
      throw Exception('Invalid server response. Please try again.');
    } catch (e) {
      _logger.e('Registration error: $e');
      rethrow;
    }
  }

  // Helper method to handle API responses
  Map<String, dynamic> _handleResponse(http.Response response) {
    _logger.d('Handling response with status: ${response.statusCode}');
    _logger.d('Response body: ${response.body}');
    
    if (response.statusCode == 401) {
      _logger.w('Unauthorized access - token may be invalid or expired');
      // TODO: Implement token refresh logic
      throw Exception('Session expired. Please log in again.');
    }
    
    if (response.statusCode == 403) {
      _logger.w('Forbidden - user does not have permission');
      throw Exception('You do not have permission to perform this action.');
    }
    
    if (response.statusCode == 404) {
      _logger.w('Resource not found');
      throw Exception('The requested resource was not found.');
    }
    
    if (response.statusCode >= 500) {
      _logger.e('Server error: ${response.statusCode}');
      throw Exception('Server error occurred. Please try again later.');
    }
    
    if (response.body.isEmpty) {
      _logger.w('Empty response body');
      return {};
    }
    _logger.d('API Response [${response.statusCode}]: ${response.body}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty 
          ? json.decode(response.body) 
          : {'success': true};
    } else {
      final error = response.body.isNotEmpty 
          ? json.decode(response.body) 
          : {'error': 'Request failed with status: ${response.statusCode}'};
      throw Exception(error['detail'] ?? error['error'] ?? 'Something went wrong');
    }
  }

  // Save authentication data to shared preferences
  Future<void> _saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String email,
  }) async {
    try {
      _authToken = accessToken;
      _refreshToken = refreshToken;
      
      await _prefs.setString('access_token', accessToken);
      await _prefs.setString('refresh_token', refreshToken);
      await _prefs.setString('user_email', email);
      
      // Update headers with the new token
      _headers['Authorization'] = 'Bearer $accessToken';
    } catch (e) {
      _logger.e('Error saving auth data: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // No backend logout endpoint; just clear local tokens
    } catch (e) {
      _logger.e('Logout error: $e');
    } finally {
      // Clear local storage
      await _prefs.remove('access_token');
      await _prefs.remove('refresh_token');
      await _prefs.remove('user_email');
      
      // Clear in-memory tokens
      _authToken = null;
      _refreshToken = null;
      
      // Clear authorization header
      _headers.remove('Authorization');
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.profile}'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      );

      final raw = _handleResponse(response);
      // Map backend user + profile into app's expected shape
      if (raw is Map<String, dynamic>) {
        final profile = raw['profile'] as Map<String, dynamic>?;
        return {
          'id': raw['id']?.toString(),
          'uid': profile != null ? (profile['custom_id']?.toString() ?? '') : (raw['id']?.toString() ?? ''),
          'email': raw['email'],
          'name': profile != null ? profile['name'] : raw['first_name'],
          'phone': profile != null ? profile['phone'] : null,
        };
      }
      return raw;
    } catch (e) {
      _logger.e('Get user data error: $e');
      return null;
    }
  }

  // Get all data sessions
  Future<Map<String, dynamic>> getSessions() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'error': 'Not authenticated'};
      }

      final response = await _client.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sessions}'),
        headers: {
          ..._headers,
          'Authorization': 'Bearer $token',
        },
      );

      _logger.d('Get sessions response: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      _logger.e('Get sessions error: $e');
      return {'error': e.toString()};
    }
  }

  // Create a new data session
  Future<Map<String, dynamic>> createSession({String? location}) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.sessions}'),
        headers: {
          ..._headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'location': location,
        }),
      );

      _logger.d('Create session response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create session',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get auth token
  Future<String?> getToken() async {
    if (_authToken != null) return _authToken;
    _authToken = _prefs.getString('access_token');
    return _authToken;
  }
  
  // Get user email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  // Upload media file
  Future<bool> uploadMedia(String filePath, int sessionId, String mediaType) async {
    try {
      final token = await getToken();
      if (token == null) return false;
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.media}')
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['session'] = sessionId.toString();
      request.fields['media_type'] = mediaType;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      final response = await request.send();
      return response.statusCode == 201;
    } catch (e) {
      _logger.e('Upload media error:', error: e);
      return false;
    }
  }

  // Add note to session
  Future<bool> addNote(int sessionId, String text) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.notes}'),
        headers: {
          ..._headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'session': sessionId, 'text': text}),
      );
      return response.statusCode == 201;
    } catch (e) {
      _logger.e('Add note error:', error: e);
      return false;
    }
  }
}
