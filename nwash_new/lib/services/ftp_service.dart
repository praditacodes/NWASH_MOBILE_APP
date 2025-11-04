// FTP service is now disabled. All code commented out.
import 'dart:io';
import 'dart:convert';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path/path.dart' as path;
import '../models/user_model.dart';
import '../models/data_session.dart';

class FTPService {
  late FTPConnect _ftpConnect;
  final String _host;
  final String _username;
  final String _password;
  final int _port;
  bool _isConnected = false;

  FTPService({
    required String host,
    required String username,
    required String password,
    int port = 21,
  })  : _host = host,
        _username = username,
        _password = password,
        _port = port {
    _ftpConnect = FTPConnect(
      _host,
      port: _port,
      user: _username,
      pass: _password,
    );
  }

  // Connection Management
  Future<bool> connect() async {
    try {
      await _ftpConnect.connect();
      _isConnected = true;
      print('FTP Connected successfully');
      return true;
    } catch (e) {
      print('FTP Connection Error: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      if (_isConnected) {
        await _ftpConnect.disconnect();
        _isConnected = false;
        print('FTP Disconnected successfully');
      }
      return true;
    } catch (e) {
      print('FTP Disconnection Error: $e');
      return false;
    }
  }

  bool get isConnected => _isConnected;

  // User Management
  Future<UserModel?> authenticateUser(String email, String password) async {
    try {
      if (!_isConnected) await connect();
      final usersDir = '/users';
      final userFile = '$usersDir/$email.json';
      final tempFile = File('${Directory.systemTemp.path}/temp_user.json');
      final success = await downloadFile(userFile, tempFile);
      if (success && await tempFile.exists()) {
        final userData = json.decode(await tempFile.readAsString());
        if (userData['password'] == password) {
          await tempFile.delete();
          return UserModel.fromJson(userData);
        }
      }
      if (await tempFile.exists()) await tempFile.delete();
      return null;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  Future<bool> registerUser(UserModel user, String password) async {
    try {
      if (!_isConnected) await connect();
      await _createDirectoryIfNotExists('/users');
      final userData = user.toJson();
      userData['password'] = password;
      final tempFile = File('${Directory.systemTemp.path}/temp_user.json');
      await tempFile.writeAsString(json.encode(userData));
      final success = await uploadFile(tempFile, '/users/${user.email}.json');
      await tempFile.delete();
      return success;
    } catch (e) {
      print('User registration error: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile(UserModel user) async {
    try {
      if (!_isConnected) await connect();
      final tempFile = File('${Directory.systemTemp.path}/temp_user.json');
      final success = await downloadFile('/users/${user.email}.json', tempFile);
      if (success && await tempFile.exists()) {
        final userData = json.decode(await tempFile.readAsString());
        final password = userData['password'];
        final updatedData = user.toJson();
        updatedData['password'] = password;
        await tempFile.writeAsString(json.encode(updatedData));
        final uploadSuccess = await uploadFile(tempFile, '/users/${user.email}.json');
        await tempFile.delete();
        return uploadSuccess;
      }
      if (await tempFile.exists()) await tempFile.delete();
      return false;
    } catch (e) {
      print('Update user profile error: $e');
      return false;
    }
  }

  // File Operations
  Future<bool> uploadFile(File localFile, String remotePath) async {
    try {
      if (!_isConnected) await connect();
      final remoteDir = path.dirname(remotePath);
      await _createDirectoryIfNotExists(remoteDir);
      await _ftpConnect.changeDirectory(remoteDir);
      await _ftpConnect.uploadFile(localFile);
      print('File uploaded successfully: $remotePath');
      return true;
    } catch (e) {
      print('FTP Upload Error: $e');
      return false;
    }
  }

  Future<bool> downloadFile(String remotePath, File localFile) async {
    try {
      if (!_isConnected) await connect();
      await _ftpConnect.downloadFile(remotePath, localFile);
      print('File downloaded successfully: $remotePath');
      return true;
    } catch (e) {
      print('FTP Download Error: $e');
      return false;
    }
  }

  Future<bool> deleteFile(String remotePath) async {
    try {
      if (!_isConnected) await connect();
      
      await _ftpConnect.deleteFile(remotePath);
      print('File deleted successfully: $remotePath');
      return true;
    } catch (e) {
      print('FTP Delete Error: $e');
      return false;
    }
  }

  Future<List<String>> listFiles(String remotePath) async {
    try {
      if (!_isConnected) await connect();
      final files = await _ftpConnect.listDirectoryContent();
      return files.map((file) => file.name).toList();
    } catch (e) {
      print('FTP List Files Error: $e');
      return [];
    }
  }

  // Data Session Management
  Future<bool> uploadSession(DataSession session, String userId) async {
    try {
      if (!_isConnected) await connect();
      
      // Create sessions directory structure
      final sessionsDir = '/sessions/$userId';
      await _createDirectoryIfNotExists(sessionsDir);
      
      // Prepare session data
      final sessionData = {
        'id': session.id,
        'userId': userId,
        'timestamp': session.timestamp.toIso8601String(),
        'photos': session.photos,
        'audios': session.audios,
        'notes': session.notes,
        'uploaded': true,
        'uploadedAt': DateTime.now().toIso8601String(),
      };
      
      // Upload session file
      final tempFile = File('${Directory.systemTemp.path}/temp_session.json');
      await tempFile.writeAsString(json.encode(sessionData));
      
      final success = await uploadFile(tempFile, '$sessionsDir/${session.id}.json');
      await tempFile.delete();
      
      return success;
    } catch (e) {
      print('Upload session error: $e');
      return false;
    }
  }

  Future<List<DataSession>> getSessions(String userId) async {
    try {
      if (!_isConnected) await connect();
      
      final sessionsDir = '/sessions/$userId';
      final files = await listFiles(sessionsDir);
      
      final sessions = <DataSession>[];
      
      for (final fileName in files) {
        if (fileName.endsWith('.json')) {
          final tempFile = File('${Directory.systemTemp.path}/temp_session_$fileName');
          final success = await downloadFile('$sessionsDir/$fileName', tempFile);
          
          if (success && await tempFile.exists()) {
            final sessionData = json.decode(await tempFile.readAsString());
            
            sessions.add(DataSession(
              id: sessionData['id'],
              timestamp: DateTime.parse(sessionData['timestamp']),
              photos: List<String>.from(sessionData['photos'] ?? []),
              audios: List<String>.from(sessionData['audios'] ?? []),
              notes: sessionData['notes'] ?? '',
              uploaded: sessionData['uploaded'] ?? true,
            ));
            
            await tempFile.delete();
          }
        }
      }
      
      // Sort by timestamp descending
      sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return sessions;
    } catch (e) {
      print('Get sessions error: $e');
      return [];
    }
  }

  // Media Upload
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      if (!_isConnected) await connect();
      
      final fileName = 'images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final success = await uploadFile(imageFile, '/media/$fileName');
      
      if (success) {
        return '/media/$fileName';
      }
      throw Exception('Failed to upload image');
    } catch (e) {
      print('Upload image error: $e');
      rethrow;
    }
  }

  Future<String> uploadAudio(File audioFile, String userId) async {
    try {
      if (!_isConnected) await connect();
      
      final fileName = 'audio/$userId/${DateTime.now().millisecondsSinceEpoch}.mp3';
      final success = await uploadFile(audioFile, '/media/$fileName');
      
      if (success) {
        return '/media/$fileName';
      }
      throw Exception('Failed to upload audio');
    } catch (e) {
      print('Upload audio error: $e');
      rethrow;
    }
  }

  // Data Storage
  Future<bool> storeData({
    required String userId,
    required String type,
    required String data,
    List<String>? mediaUrls,
    Map<String, dynamic>? metadata,
    required DateTime timestamp,
  }) async {
    try {
      if (!_isConnected) await connect();
      
      final dataDir = '/data/$userId';
      await _createDirectoryIfNotExists(dataDir);
      
      final dataDoc = {
        'userId': userId,
        'type': type,
        'data': data,
        'mediaUrls': mediaUrls ?? [],
        'metadata': metadata ?? {},
        'timestamp': timestamp.toIso8601String(),
        'syncedAt': DateTime.now().toIso8601String(),
      };
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.json';
      final tempFile = File('${Directory.systemTemp.path}/temp_data.json');
      await tempFile.writeAsString(json.encode(dataDoc));
      
      final success = await uploadFile(tempFile, '$dataDir/$fileName');
      await tempFile.delete();
      
      return success;
    } catch (e) {
      print('Store data error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getData(String userId) async {
    try {
      if (!_isConnected) await connect();
      
      final dataDir = '/data/$userId';
      final files = await listFiles(dataDir);
      
      final dataList = <Map<String, dynamic>>[];
      
      for (final fileName in files) {
        if (fileName.endsWith('.json')) {
          final tempFile = File('${Directory.systemTemp.path}/temp_data_$fileName');
          final success = await downloadFile('$dataDir/$fileName', tempFile);
          
          if (success && await tempFile.exists()) {
            final data = json.decode(await tempFile.readAsString());
            dataList.add(data);
            await tempFile.delete();
          }
        }
      }
      
      // Sort by timestamp descending
      dataList.sort((a, b) => DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp'])));
      return dataList;
    } catch (e) {
      print('Get data error: $e');
      return [];
    }
  }

  // Helper Methods
  Future<void> _createDirectoryIfNotExists(String remotePath) async {
    try {
      final pathParts = remotePath.split('/').where((part) => part.isNotEmpty).toList();
      String currentPath = '';
      for (final part in pathParts) {
        currentPath += '/$part';
        try {
          await _ftpConnect.makeDirectory(currentPath);
        } catch (e) {
          // Directory might already exist, continue
        }
      }
    } catch (e) {
      print('Create directory error: $e');
    }
  }

  // Cleanup
  void dispose() {
    disconnect();
  }
}
