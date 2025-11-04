import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/capture_provider.dart';
// import '../services/ftp_service.dart';
import 'package:path/path.dart' as path;

class CaptureScreen extends StatefulWidget {
  @override
  _CaptureScreenState createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  // final FTPService _ftpService = FTPService(
  //   host: 'YOUR_FTP_HOST',
  //   username: 'YOUR_FTP_USER',
  //   password: 'YOUR_FTP_PASS',
  // );
  List<Map<String, dynamic>> _capturedMedia = [];
  String? _currentAudioPath;
  bool _isRecording = false;
  bool _isSynced = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('CaptureScreen initialized');
    _loadData();
  }

  Future<void> _loadData() async {
    print('Loading data...');
    setState(() => _isLoading = true);
    try {
      final userId = Provider.of<SettingsProvider>(context, listen: false).userId;
      print('User ID: $userId');
      // TODO: Load data from FTP/local storage instead of Firestore
      // setState(() { _capturedMedia = ... });
    } catch (e) {
      print('Error loading data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _captureImage() async {
    print('Starting image capture...');
    if (_capturedMedia.where((m) => m['type'] == 'image').length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum 5 photos allowed')),
      );
      return;
    }
    final status = await Permission.camera.request();
    print('Camera permission status: $status');
    if (status.isGranted) {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        print('Image captured: ${image.path}');
        setState(() => _isLoading = true);
        try {
          final userId = Provider.of<SettingsProvider>(context, listen: false).userId;
          print('Uploading image for user: $userId');
          final imageFile = File(image.path);
          print('Image file size: ${await imageFile.length()} bytes');
          // await _ftpService.uploadFile(File(imageFile.path), '/images/$userId/${path.basename(imageFile.path)}');
          // TODO: Store metadata locally or on FTP as needed
          setState(() => _isSynced = true);
        } catch (e) {
          print('Error during image upload: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      final directory = await getApplicationDocumentsDirectory();
      final userId = Provider.of<SettingsProvider>(context, listen: false).userId;
      final userDir = Directory('${directory.path}/$userId');
      if (!await userDir.exists()) {
        await userDir.create(recursive: true);
      }
      final audioPath = '${userDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentAudioPath = audioPath;
      try {
        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: audioPath,
        );
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isLoading = true;
      });
      if (_currentAudioPath != null) {
        final userId = Provider.of<SettingsProvider>(context, listen: false).userId;
        final audioFile = File(_currentAudioPath!);
        // await _ftpService.uploadFile(File(audioFile.path), '/audio/$userId/${path.basename(audioFile.path)}');
        // TODO: Store metadata locally or on FTP as needed
        setState(() => _isSynced = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload audio: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Capture Photos & Audio'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _capturedMedia.length,
                    itemBuilder: (context, index) {
                      final media = _capturedMedia[index];
                      return Stack(
                        children: [
                          if (media['type'] == 'image')
                            Image.network(
                              media['url'],
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.audio_file, size: 50),
                            ),
                          if (media['synced'])
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Icon(Icons.check_circle, color: Colors.green),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _captureImage,
                        icon: Icon(Icons.camera_alt),
                        label: Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(_isRecording ? 'Stop Recording' : 'Record Audio'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
} 