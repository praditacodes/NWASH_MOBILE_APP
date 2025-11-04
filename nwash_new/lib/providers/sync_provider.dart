import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/connectivity_service.dart'; 
import 'package:connectivity_plus/connectivity_plus.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SyncProvider with ChangeNotifier {
  final ApiService _apiService;
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isSyncing = false;
  bool _isOnline = false;
  int _pendingDataCount = 0;
  String? _lastSyncError;

  bool get isSyncing => _isSyncing;
  bool get isOnline => _isOnline;
  int get pendingDataCount => _pendingDataCount;
  String? get lastSyncError => _lastSyncError;

  SyncProvider(this._apiService) {
    _initConnectivityListener();
    _checkInitialConnectivity();
    _updatePendingDataCount();
  }

  // Listen to connectivity changes from ConnectivityService
  void _initConnectivityListener() {
    _connectivityService.onConnectivityChanged.listen((ConnectivityResult result) { 
      final currentlyOnline = _connectivityService.isOnline(result);
      if (_isOnline != currentlyOnline) { 
        _isOnline = currentlyOnline;
        notifyListeners();
        if (_isOnline) {
          syncData(); 
        }
      }
    });
  }

  // Check initial connectivity state
  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivityService.checkConnectivity(); 
    _isOnline = _connectivityService.isOnline(result);
    notifyListeners();
  }

  // Method to trigger synchronization
  Future<void> syncData() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      // Get all pending sessions from local storage
      final prefs = await SharedPreferences.getInstance();
      final pendingSessions = prefs.getStringList('pending_sessions') ?? [];
      
      for (final sessionJson in pendingSessions) {
        try {
          final sessionData = json.decode(sessionJson);
          // Here you would implement your actual sync logic with the API
          // For example:
          // final response = await _apiService.createSession(sessionData);
          // 
          // if (response['success'] == true) {
          //   // Remove from pending on success
          //   pendingSessions.remove(sessionJson);
          //   await prefs.setStringList('pending_sessions', pendingSessions);
          // } else {
          //   throw Exception(response['error'] ?? 'Failed to sync session');
          // }
        } catch (e) {
          _lastSyncError = 'Error syncing data: $e';
          print(_lastSyncError);
          // Continue with next item on error
          continue;
        }
      }
      
      // Update pending count
      await _updatePendingDataCount();
      
    } catch (e) {
      _lastSyncError = 'Sync failed: $e';
      print(_lastSyncError);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // Update pending data count
  Future<void> _updatePendingDataCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingSessions = prefs.getStringList('pending_sessions') ?? [];
      _pendingDataCount = pendingSessions.length;
      notifyListeners();
    } catch (e) {
      print('Error updating pending data count: $e');
    }
  }

  // Store data for later sync
  Future<void> storeData({
    required String type,
    required Map<String, dynamic> data,
    List<String> mediaPaths = const [],
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingSessions = prefs.getStringList('pending_sessions') ?? [];
      
      // Add the new session to pending
      final sessionData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'type': type,
        'data': data,
        'media_paths': mediaPaths,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      pendingSessions.add(json.encode(sessionData));
      await prefs.setStringList('pending_sessions', pendingSessions);
      
      // Update the pending count
      await _updatePendingDataCount();
      
      // Try to sync if online
      if (_isOnline) {
        await syncData();
      }
    } catch (e) {
      print('Error storing data: $e');
      rethrow;
    }
  }

  // Expose getPendingData for History screen
  Future<List<Map<String, dynamic>>> getPendingData() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingSessions = prefs.getStringList('pending_sessions') ?? [];
    return pendingSessions.map((sessionJson) => json.decode(sessionJson) as Map<String, dynamic>).toList();
  }
}