import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  String name = '';
  String phone = '';
  String userId = '';

  SettingsProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    name = prefs.getString('name_$email') ?? '';
    phone = prefs.getString('phone_$email') ?? '';
    
    // Check if user is already authenticated
    // User? currentUser = _auth.currentUser;
    if (/*currentUser != null*/ false) {
      userId = /*currentUser.uid*/ '';
    } else {
      // Create anonymous user if not authenticated
      // try {
      //   UserCredential userCredential = await _auth.signInAnonymously();
      //   userId = userCredential.user!.uid;
      //   await prefs.setString('userId', userId);
      // } catch (e) {
      userId = _generateUserId();
      // await prefs.setString('userId', userId);
    }
    notifyListeners();
  }

  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
  }

  Future<void> updateName(String value) async {
    name = value;
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    await prefs.setString('name_$email', name);
    notifyListeners();
  }

  Future<void> updatePhone(String value) async {
    phone = value;
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';
    await prefs.setString('phone_$email', phone);
    notifyListeners();
  }

  void clearUserInfo() {
    name = '';
    phone = '';
    notifyListeners();
  }
}