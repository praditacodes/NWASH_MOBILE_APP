import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_session.dart';
import '../services/api_service.dart'; // Added import for ApiService

class LocalStorageService {
  static String _key(String userEmail) => 'data_sessions_$userEmail';

  Future<String?> _getCurrentUserEmail() async {
    // You may need to adjust this if you use a different method to get the current user
    // For now, use ApiService.getEmail()
    return await ApiService.getEmail();
  }

  Future<void> saveSession(DataSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = await _getCurrentUserEmail();
    print('Saving session for user: $userEmail');
    if (userEmail == null) return;
    List<String> sessions = prefs.getStringList(_key(userEmail)) ?? [];

    // Add new session JSON string
    sessions.add(jsonEncode(session.toJson()));

    await prefs.setStringList(_key(userEmail), sessions);
    print('Saved session. Total sessions now: ${sessions.length}');
  }

  Future<void> saveDraftSession(DataSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = await _getCurrentUserEmail();
    print('Saving draft session for user: $userEmail');
    if (userEmail == null) return;
    List<String> sessions = prefs.getStringList(_key(userEmail)) ?? [];
    // Mark as draft
    final draftSession = session.copyWith(draft: true);
    sessions.add(jsonEncode(draftSession.toJson()));
    await prefs.setStringList(_key(userEmail), sessions);
    print('Saved draft session. Total sessions now: ${sessions.length}');
  }

  Future<List<DataSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = await _getCurrentUserEmail();
    print('Loading sessions for user: $userEmail');
    if (userEmail == null) return [];
    List<String> sessions = prefs.getStringList(_key(userEmail)) ?? [];
    print('Loaded sessions for $userEmail: $sessions');
    return sessions.map((e) => DataSession.fromJson(jsonDecode(e))).toList();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = await _getCurrentUserEmail();
    if (userEmail == null) return;
    await prefs.remove(_key(userEmail));
    print('Cleared all saved sessions');
  }

  static Future<void> clearAllStatic(String userEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userEmail));
    print('Cleared all saved sessions (static method)');
  }
}
