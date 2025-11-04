import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_service.dart';

class StorageService {
  final _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  // Get the nwash directory (app-specific so it works on Android 11+ without MANAGE_EXTERNAL_STORAGE)
  static Future<Directory> get _nwashDirectory async {
    if (Platform.isAndroid) {
      // Use app-specific external storage directory
      final baseDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final dir = Directory(path.join(baseDir.path, 'nwash'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      // For iOS, use documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final nwashDir = Directory('${appDir.path}/nwash');
      if (!await nwashDir.exists()) {
        await nwashDir.create(recursive: true);
      }
      return nwashDir;
    }
  }

  // Resolve a user-scoped base directory, e.g. .../nwash/<user-key>
  static Future<Directory> _userBaseDirectory() async {
    final base = await _nwashDirectory;
    final email = await ApiService.getEmail();
    final userKey = (email ?? 'anonymous')
        .replaceAll('@', '_at_')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-\.]'), '_');
    final dir = Directory(path.join(base.path, userKey));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // Get the images directory
  static Future<Directory> getImageDirectory() async {
    final userBase = await _userBaseDirectory();
    final imageDir = Directory(path.join(userBase.path, 'images'));
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    print('StorageService: Image Directory Path: ${imageDir.path}');
    return imageDir;
  }

  // Get the voice directory
  static Future<Directory> getVoiceDirectory() async {
    final userBase = await _userBaseDirectory();
    final voiceDir = Directory(path.join(userBase.path, 'voice'));
    if (!await voiceDir.exists()) {
      await voiceDir.create(recursive: true);
    }
    print('StorageService: Voice Directory Path: ${voiceDir.path}');
    return voiceDir;
  }

  // Get the notes directory
  static Future<Directory> getNotesDirectory() async {
    final userBase = await _userBaseDirectory();
    final notesDir = Directory(path.join(userBase.path, 'notes'));
    if (!await notesDir.exists()) {
      await notesDir.create(recursive: true);
    }
    print('StorageService: Notes Directory Path: ${notesDir.path}');
    return notesDir;
  }

  // Request storage permissions
  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    // App-specific external storage does not require broad storage permissions on Android 11+.
    // For older Android versions, request the legacy storage permission gracefully.
    final status = await Permission.storage.request();
    return status.isGranted || status.isLimited || status.isDenied;
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Save an image file
  Future<String> saveImage(File imageFile) async {
    if (!await requestStoragePermission()) {
      throw Exception('Storage permission not granted');
    }

    final imageDir = await getImageDirectory();
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy('${imageDir.path}/$fileName');
    print('StorageService: Saved image to: ${savedImage.path}');
    return savedImage.path;
  }

  // Save a voice recording
  Future<String?> saveVoice(File audioFile) async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Microphone permission not granted');
    }

    final voiceDir = await getVoiceDirectory();
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final savedVoice = await audioFile.copy('${voiceDir.path}/$fileName');
    print('StorageService: Saved voice to: ${savedVoice.path}');
    return savedVoice.path;
  }

  // Save a note
  Future<String> saveNote(String noteText) async {
    if (!await requestStoragePermission()) {
      throw Exception('Storage permission not granted');
    }

    final notesDir = await getNotesDirectory();
    final fileName = 'note_${DateTime.now().millisecondsSinceEpoch}.txt';
    final noteFile = File('${notesDir.path}/$fileName');
    await noteFile.writeAsString(noteText);
    print('StorageService: Saved note to: ${noteFile.path}');
    return noteFile.path;
  }

  // Get all stored images
  static Future<List<File>> getStoredImages() async {
    if (!await requestStoragePermission()) {
      throw Exception('Storage permission not granted');
    }

    final imageDir = await getImageDirectory();
    final files = await imageDir.list().toList();
    return files.whereType<File>().toList();
  }

  // Get all stored voice recordings
  static Future<List<File>> getStoredVoiceFiles() async {
    if (!await requestStoragePermission()) {
      throw Exception('Storage permission not granted');
    }

    final voiceDir = await getVoiceDirectory();
    final files = await voiceDir.list().toList();
    return files.whereType<File>().toList();
  }

  // Get all stored notes
  static Future<List<File>> getStoredNotes() async {
    if (!await requestStoragePermission()) {
      throw Exception('Storage permission not granted');
    }

    final notesDir = await getNotesDirectory();
    final files = await notesDir.list().toList();
    return files.whereType<File>().toList();
  }

  // Delete a file
  static Future<void> deleteFile(String filePath) async {
    if (!await requestStoragePermission()) {
      throw Exception('Storage permission not granted');
    }

    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Get file size
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  // Get total storage used
  static Future<int> getTotalStorageUsed() async {
    if (!await requestStoragePermission()) {
      throw Exception('Storage permission not granted');
    }

    final nwashDir = await _nwashDirectory;
    int totalSize = 0;
    
    await for (final file in nwashDir.list(recursive: true)) {
      if (file is File) {
        totalSize += await file.length();
      }
    }
    
    return totalSize;
  }

  // Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  Future<String?> takePhoto() async {
    if (!await requestCameraPermission()) {
      throw Exception('Camera permission not granted');
    }

    if (!await requestStoragePermission()) {
      throw Exception('Storage permission not granted');
    }

    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image == null) {
      return null;
    }

    return saveImage(File(image.path));
  }

  Future<String?> recordAudio() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Microphone permission not granted');
    }

    if (await _audioRecorder.hasPermission()) {
      final voiceDir = await getVoiceDirectory();
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final filePath = '${voiceDir.path}/$fileName';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      return filePath;
    }
    return null;
  }

  Future<String?> stopRecording() async {
    if (await _audioRecorder.isRecording()) {
      final filePath = await _audioRecorder.stop();
      if (filePath != null) {
        // The file is already saved in the correct location, just return the path
        return filePath;
      }
    }
    return null;
  }

  Future<bool> isRecording() async {
    return _audioRecorder.isRecording();
  }

  void dispose() {
    _audioRecorder.dispose();
  }
} 