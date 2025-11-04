// class ApiConfig {
//   // Base URL - Configured for local development
//   // For physical device on same network (using your computer's local IP):
//   static const String baseUrl = 'http://192.168.1.114:8000';
  
//   // For local development with Django runserver (on your computer):
//   // static const String baseUrl = 'http://127.0.0.1:8000';
  
//   // For Android emulator:
//   // static const String baseUrl = 'http://10.0.2.2:8000';
  
//   // Authentication Endpoints
//   static const String login = '/api/token/';
//   static const String refreshToken = '/api/token/refresh/';
//   static const String verifyToken = '/api/token/verify/';
//   static const String register = '/api/register/';
  
//   // User Endpoints
//   static const String userProfile = '/api/profile/';
  
//   // App Endpoints
//   static const String sessions = '/api/sessions/';
//   static const String media = '/api/media/';
//   static const String notes = '/api/notes/';
//   static const String services = '/api/services/';
  
//   // Timeouts
//   static const Duration connectTimeout = Duration(seconds: 30);
//   static const Duration receiveTimeout = Duration(seconds: 30);
  
//   // Headers
//   static const Map<String, String> headers = {
//     'Content-Type': 'application/json',
//     'Accept': 'application/json',
//   };
  
//   // Check if the API configuration is valid
//   static bool get isValid => baseUrl.isNotEmpty && !baseUrl.contains('your-render-app');
  
//   // Get full URL for an endpoint
//   static String getUrl(String endpoint) {
//     if (endpoint.startsWith('http')) return endpoint;
//     return '$baseUrl${endpoint.startsWith('/') ? '' : '/'}$endpoint';
//   }
// }


// lib/config/api_config.dart
class ApiConfig {
  // Default for Android emulator
  static const String baseUrl = 'http://192.168.1.114:8000';
  
  
  // For physical device (use your computer's local IP)
  // static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000';
  
  // Authentication endpoints
  static const String login = '/api/token/';
  static const String refreshToken = '/api/token/refresh/';
  static const String verifyToken = '/api/token/verify/';
  static const String register = '/api/register/';
  
  // User endpoints
  static const String profile = '/api/profile/';
  static const String services = '/api/services/';
  static const String sessions = '/api/sessions/';
  static const String media = '/api/media/';
  static const String notes = '/api/notes/';
}