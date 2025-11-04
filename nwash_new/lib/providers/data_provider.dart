import 'package:flutter/foundation.dart';
import '../models/data_session.dart';
import '../services/api_service.dart';
import 'dart:io';

class DataProvider with ChangeNotifier {
  final ApiService _apiService;
  List<DataSession> _sessions = [];
  bool _isLoading = false;
  String? _currentUserId;
  String? _error;

  DataProvider(this._apiService);

  List<DataSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set current user ID for data operations
  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  Future<void> loadSessions() async {
    if (_currentUserId == null) {
      print('No current user set for loading sessions');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getSessions();
      
      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        _sessions = data
            .map((item) => DataSession.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _error = response['error'] ?? 'Failed to load sessions';
      }
      // Sort by date (newest first)
      _sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      print('Loaded ${_sessions.length} sessions');
    } catch (e) {
      print('Error loading sessions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSession(DataSession session) async {
    try {
      // Store locally first
      // await _dataSyncService.storeDataLocally(
      //   type: 'session',
      //   data: session.toJson(),
      //   mediaPaths: [...session.photos, ...session.audios],
      // );

      // Add to local list
      _sessions.insert(0, session);
      notifyListeners();

      // Try to sync if online
      // await _syncSessionToFTP(session);
    } catch (e) {
      print('Error adding session: $e');
      rethrow;
    }
  }

  Future<void> saveSessions() async {
    try {
      for (final session in _sessions) {
        if (!session.uploaded) {
          // await _dataSyncService.storeDataLocally(
          //   type: 'session',
          //   data: session.toJson(),
          //   mediaPaths: [...session.photos, ...session.audios],
          // );
        }
      }
    } catch (e) {
      print('Error saving sessions: $e');
      rethrow;
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      final session = _sessions.firstWhere((s) => s.id == id);
      _sessions.removeWhere((session) => session.id == id);
      notifyListeners();
      
      // Try to delete from FTP server
      if (_currentUserId != null) {
        try {
          // await _ftpService.deleteFile('/sessions/$_currentUserId/$id.json');
        } catch (e) {
          print('Error deleting from FTP: $e');
        }
      }
      
      await saveSessions();
    } catch (e) {
      print('Error deleting session: $e');
      rethrow;
    }
  }

  Future<void> updateSession(DataSession session) async {
    try {
      final index = _sessions.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        _sessions[index] = session;
        notifyListeners();
        
        // Try to update on FTP server
        // await _syncSessionToFTP(session);
        
        await saveSessions();
      }
    } catch (e) {
      print('Error updating session: $e');
      rethrow;
    }
  }

  Future<void> _syncSessionToFTP(DataSession session) async {
    if (_currentUserId == null) return;

    try {
      // if (await _ftpService.connect()) {
      //   // Upload media files first
      //   final updatedPhotos = <String>[];
      //   final updatedAudios = <String>[];

      //   for (final photoPath in session.photos) {
      //     try {
      //       final file = File(photoPath);
      //       if (await file.exists()) {
      //         final remotePath = await _ftpService.uploadImage(file, _currentUserId!);
      //         updatedPhotos.add(remotePath);
      //       }
      //     } catch (e) {
      //       print('Error uploading photo: $e');
      //       updatedPhotos.add(photoPath); // Keep local path if upload fails
      //     }
      //   }

      //   for (final audioPath in session.audios) {
      //     try {
      //       final file = File(audioPath);
      //       if (await file.exists()) {
      //         final remotePath = await _ftpService.uploadAudio(file, _currentUserId!);
      //         updatedAudios.add(remotePath);
      //       }
      //     } catch (e) {
      //       print('Error uploading audio: $e');
      //       updatedAudios.add(audioPath); // Keep local path if upload fails
      //     }
      //   }

      //   // Create updated session with remote paths
      //   final updatedSession = DataSession(
      //     id: session.id,
      //     timestamp: session.timestamp,
      //     photos: updatedPhotos,
      //     audios: updatedAudios,
      //     notes: session.notes,
      //     uploaded: true,
      //   );

      //   // Upload session data
      //   await _ftpService.uploadSession(updatedSession, _currentUserId!);
        
      //   // Update local session
      //   final index = _sessions.indexWhere((s) => s.id == session.id);
      //   if (index != -1) {
      //     _sessions[index] = updatedSession;
      //     notifyListeners();
      //   }
      // }
    } catch (e) {
      print('Error syncing session to FTP: $e');
    }
  }

  Future<void> syncAllPendingData() async {
    try {
      // final pendingData = await _dataSyncService.getPendingData();
      
      // for (final data in pendingData) {
      //   if (data['type'] == 'session') {
      //     final session = DataSession.fromJson(data['data'] as Map<String, dynamic>);
      //     // await _syncSessionToFTP(session);
      //   }
      // }
      
      // Clear pending data after successful sync
      // await _dataSyncService.clearPendingData();
    } catch (e) {
      print('Error syncing pending data: $e');
    }
  }

  // Dispose
  @override
  void dispose() {
    // _ftpService.dispose();
    super.dispose();
  }
}