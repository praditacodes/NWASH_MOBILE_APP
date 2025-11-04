import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/data_session.dart';
import '../services/api_service.dart'; // Added import for ApiService
import 'storage_service.dart';
import 'local_storage_service.dart';

class DataSyncService {
  static String _pendingDataKey(String userEmail) => 'pending_data_$userEmail';

  Future<String?> _getCurrentUserEmail() async {
    return await ApiService.getEmail();
  }

  Future<List<Map<String, dynamic>>> getPendingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = await _getCurrentUserEmail();
      if (userEmail == null) return [];
      final pendingDataJson = prefs.getStringList(_pendingDataKey(userEmail)) ?? [];
      final parsedData = pendingDataJson.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
      return parsedData;
    } catch (e) {
      return [];
    }
  }

  Future<void> storeDataLocally({
    required String type,
    required Map<String, dynamic> data,
    List<String>? mediaPaths,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = await _getCurrentUserEmail();
      if (userEmail == null) return;
      final pendingData = await getPendingData();
      final newData = {
        'type': type,
        'data': data,
        'mediaPaths': mediaPaths,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      };
      pendingData.add(newData);
      await prefs.setStringList(
        _pendingDataKey(userEmail),
        pendingData.map((item) => jsonEncode(item)).toList(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncPendingData() async {
    print('syncPendingData called');
    final userEmail = await _getCurrentUserEmail();
    if (userEmail == null) {
      print('No user email found for sync.');
      return;
    }
    final pendingData = await getPendingData();
    print('Pending data count:  [36m [1m${pendingData.length} [0m');
    if (pendingData.isEmpty) {
      print('No pending data to sync.');
      return;
    }
    final List<Map<String, dynamic>> failedToSync = [];
    final localStorage = LocalStorageService();
    for (final data in pendingData) {
      bool sessionSynced = false;
      try {
        print('Syncing data: $data');
        // 1. Create session on server and get its ID
        final location = data['data']['location'] ?? '';
        print('Creating session with location: $location');
        final sessionResponse = await ApiService.createSession(location: location);
        print('Session response: $sessionResponse');
        if (sessionResponse == null || sessionResponse['id'] == null) {
          throw Exception('Session creation failed or did not return an ID');
        }
        final sessionId = sessionResponse['id'];

        // 2. Upload media files
        if (data['mediaPaths'] != null) {
          for (final path in data['mediaPaths']) {
            if (path != null && path is String && File(path).existsSync()) {
              final mediaType = path.toLowerCase().endsWith('.mp3') || path.toLowerCase().endsWith('.wav') || path.toLowerCase().endsWith('.m4a') ? 'audio' : 'image';
              print('Uploading media: $path as $mediaType');
              final uploadSuccess = await ApiService.uploadMedia(path, sessionId, mediaType);
              print('Upload media $path: $uploadSuccess');
              if (!uploadSuccess) throw Exception('Media upload failed for $path');
              // Delete file after successful upload
              try {
                await StorageService.deleteFile(path);
                print('Deleted local file after upload: $path');
              } catch (e) {
                print('Failed to delete file $path: $e');
              }
            }
          }
        }

        // 3. Upload notes
        final notes = data['data']['notes'] ?? '';
        if (notes.isNotEmpty) {
          print('Adding note: $notes');
          final noteSuccess = await ApiService.addNote(sessionId, notes);
          print('Add note: $noteSuccess');
          if (!noteSuccess) throw Exception('Note upload failed');
        }
        print('Sync successful for session with local timestamp: ${data['timestamp']}');
        sessionSynced = true;
      } catch (e) {
        print('Sync failed for session: $e');
        failedToSync.add(data);
      }
      // Save as synced session if successful
      if (sessionSynced) {
        try {
          // Compose DataSession from data
          final session = DataSession(
            id: data['data']['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: data['data']['timestamp'] != null ? DateTime.tryParse(data['data']['timestamp']) ?? DateTime.now() : DateTime.now(),
            photos: data['mediaPaths'] != null ? List<String>.from(data['mediaPaths'].where((p) => p != null && p is String && (p.toLowerCase().endsWith('.jpg') || p.toLowerCase().endsWith('.jpeg') || p.toLowerCase().endsWith('.png')))) : [],
            audios: data['mediaPaths'] != null ? List<String>.from(data['mediaPaths'].where((p) => p != null && p is String && (p.toLowerCase().endsWith('.mp3') || p.toLowerCase().endsWith('.wav') || p.toLowerCase().endsWith('.m4a')))) : [],
            notes: data['data']['notes'] ?? '',
            uploaded: true,
            draft: false,
          );
          await localStorage.saveSession(session);
          print('Saved synced session locally for offline history.');
        } catch (e) {
          print('Failed to save synced session locally: $e');
        }
      }
    }
    // Save only failed items back to pending
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _pendingDataKey(userEmail),
      failedToSync.map((item) => jsonEncode(item)).toList(),
    );
    print('Sync complete. Failed to sync count: ${failedToSync.length}');
  }

  Future<int> getPendingDataCount() async {
    final pendingData = await getPendingData();
    return pendingData.length;
  }
}