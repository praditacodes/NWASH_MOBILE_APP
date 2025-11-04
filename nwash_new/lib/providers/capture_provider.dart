import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connectivity_service.dart';

class CaptureProvider with ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isSynced = false;
  bool _isOnline = false;
  String? _lastSyncTime;
  List<String> _pendingFiles = [];

  bool get isSynced => _isSynced;
  bool get isOnline => _isOnline;
  String? get lastSyncTime => _lastSyncTime;
  List<String> get pendingFiles => _pendingFiles;

  CaptureProvider() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    // Initial connectivity check using the adapted service
    final result = await _connectivityService.checkConnectivity(); // Now returns single ConnectivityResult
     _isOnline = _connectivityService.isOnline(result); // Use helper
    notifyListeners();

    // Listen to connectivity changes from the adapted service (emits single ConnectivityResult)
    _connectivityService.onConnectivityChanged.listen((ConnectivityResult result) { // Listen for single ConnectivityResult
       _isOnline = _connectivityService.isOnline(result); // Use helper
      notifyListeners();
      // ... rest of listener logic (e.g., triggering UI updates or actions based on connectivity)
    });
  }

  Future<List<File>> getLocalFiles(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final userDir = Directory('${directory.path}/$userId');
    
    if (!await userDir.exists()) {
      return [];
    }

    final files = await userDir.list().toList();
    return files.whereType<File>().toList();
  }

  void updateSyncStatus(bool synced, {String? syncTime}) {
    _isSynced = synced;
    if (syncTime != null) {
      _lastSyncTime = syncTime;
    }
    notifyListeners();
  }

  void addPendingFile(String filePath) {
    _pendingFiles.add(filePath);
    notifyListeners();
  }

  void clearPendingFiles() {
    _pendingFiles.clear();
    notifyListeners();
  }
} 