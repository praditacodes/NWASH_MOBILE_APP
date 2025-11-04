import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import 'dart:io'; // Required for File
import '../services/local_storage_service.dart'; // Import LocalStorageService
import '../models/data_session.dart'; // Import DataSession

class CollectDataScreen extends StatefulWidget {
  const CollectDataScreen({Key? key}) : super(key: key);

  @override
  _CollectDataScreenState createState() => _CollectDataScreenState();
}

class _CollectDataScreenState extends State<CollectDataScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _notesController = TextEditingController();
  List<String?> _photoPaths = List.filled(5, null);
  List<String?> _audioPaths = List.filled(5, null);
  bool _isRecording = false;
  String? _currentRecordingPath;

  // Check if there is at least one photo or audio captured
  bool get _isSavable =>
      _photoPaths.any((path) => path != null) ||
      _audioPaths.any((path) => path != null);

  @override
  void dispose() {
    // Save draft if there is any data entered
    final notes = _notesController.text;
    final photosToSave = _photoPaths.where((path) => path != null).cast<String>().toList();
    final audioToSave = _audioPaths.where((path) => path != null).cast<String>().toList();
    if (notes.isNotEmpty || photosToSave.isNotEmpty || audioToSave.isNotEmpty) {
      final draftSession = DataSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        photos: photosToSave,
        audios: audioToSave,
        notes: notes,
        uploaded: false,
        draft: true,
      );
      LocalStorageService().saveDraftSession(draftSession);
    }
    _notesController.dispose();
    _storageService.dispose();
    super.dispose();
  }

  Future<void> _takePhoto(int index) async {
    try {
      print('Attempting to take photo for index: $index');
      final path = await _storageService.takePhoto();
      if (path != null) {
        print('Photo captured successfully, path: $path');
        setState(() {
          _photoPaths[index] = path;
        });
         // Show a temporary confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured!'),
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        print('Photo capture cancelled or failed.');
         // Show a temporary cancellation/failure message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo capture cancelled or failed.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Handle error, e.g., show a SnackBar
      print('Error taking photo: $e');
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  Future<void> _recordAudio() async {
    try {
      if (!_isRecording) {
        print('Attempting to start audio recording.');
        final path = await _storageService.recordAudio();
        if (path != null) {
          setState(() {
            _isRecording = true;
            _currentRecordingPath = path;
          });
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording started...'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        print('Attempting to stop audio recording.');
        final path = await _storageService.stopRecording();
        if (path != null) {
           // Find the first available slot or replace the last one if all are filled
           int indexToSave = _audioPaths.indexOf(null);
           if (indexToSave == -1) { // All slots are filled, replace the last one
             indexToSave = _audioPaths.length - 1;
           }
           setState(() {
             _audioPaths[indexToSave] = path;
             _isRecording = false;
             _currentRecordingPath = null;
           });
            print('Audio recording stopped, path: $path');
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recording stopped!'),
                duration: Duration(seconds: 1),
              ),
            );
        } else {
           setState(() {
             _isRecording = false;
             _currentRecordingPath = null;
           });
            print('Audio recording stopped, but no file path returned.');
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Recording stopped, but failed to save.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 1),
              ),
            );
        }
      }
    } catch (e) {
      // Handle error
      print('Error recording audio: $e');
      setState(() {
         _isRecording = false;
         _currentRecordingPath = null;
      });
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording audio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  void _saveInventory() async {
    print('Attempting to save inventory.');
    // Gather data
    final notes = _notesController.text;
    final photosToSave = _photoPaths.where((path) => path != null).cast<String>().toList();
    final audioToSave = _audioPaths.where((path) => path != null).cast<String>().toList();

    print('_photoPaths: $_photoPaths');
    print('_audioPaths: $_audioPaths');
    print('photosToSave count: ${photosToSave.length}');
    print('audioToSave count: ${audioToSave.length}');

    // Basic validation: require at least one photo or audio
    if (photosToSave.isEmpty && audioToSave.isEmpty) {
      // Show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture at least one photo or audio recording.'),
        ),
      );
      print('Validation failed: No photo or audio captured.');
      return;
    }

    try {
      // Save notes to external storage if there are any
      String? notesPath;
      if (notes.isNotEmpty) {
        notesPath = await _storageService.saveNote(notes);
      }

      // Prepare data for syncing
      final sessionData = {
        'notes': notes,
        // Add other data fields as needed based on your DataSession model
      };

      final mediaPaths = [...photosToSave, ...audioToSave];
      if (notesPath != null) {
        mediaPaths.add(notesPath);
      }

      print('Media paths to save: $mediaPaths');

      // Use SyncProvider to store data
      await Provider.of<SyncProvider>(context, listen: false).storeData(
        type: 'session', // Or another type if you have different data types
        data: sessionData,
        mediaPaths: mediaPaths,
      );

      // Clear fields after saving
      setState(() {
        _notesController.clear();
        _photoPaths = List.filled(5, null);
        _audioPaths = List.filled(5, null);
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inventory saved locally and queued for sync.'),
        ),
      );
      print('Inventory saved successfully.');
    } catch (e) {
      print('Error saving inventory: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving inventory: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMediaSlot(int index, String? path, bool isPhoto) {
    final size = 60.0;
    final isEmpty = path == null;
    final borderColor = isEmpty ? Colors.grey[400] : Colors.green; // Green if filled

    return GestureDetector(
      onTap: isEmpty
          ? (isPhoto ? () => _takePhoto(index) : () => _recordAudio()) // Tap to capture/record
          : null, // Disable tap if filled for simplicity, could add view/playback logic later
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isEmpty ? Colors.grey[300] : Colors.white, // Gray if empty, white if filled
          borderRadius: BorderRadius.circular(8), // Slightly rounded
          border: Border.all(color: borderColor!), // Border color
        ),
        child: isEmpty
            ? Center(
                child: Text(
                  (index + 1).toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 18),
                ),
              )
            : (isPhoto
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7), // Match container
                    child: Image.file(
                      File(path!),
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                       errorBuilder: (context, error, stackTrace) {
                        return Center(child: Icon(Icons.error)); // Show error icon if image fails to load
                      },
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.graphic_eq, // Waveform icon for audio
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                  )),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Collect Data',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[600], // Solid blue background
        elevation: 4.0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0), // Main screen padding
        child: ListView(
          children: [
            // WASH Asset Data Collection Card
            Card(
              margin: const EdgeInsets.only(bottom: 16.0), // Margin below the card
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'WASH Asset Data\nCollection',
                        style: TextStyle(color: Colors.blueGrey, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isSavable ? _saveInventory : null, // Disable if not savable
                      icon: const Icon(Icons.save, color: Colors.white), // Floppy disk icon
                      label: const Text('Save Inventory', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isSavable ? Colors.green[600] : Colors.grey, // Green if active, grey if disabled
                        foregroundColor: Colors.white, // Text/icon color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20), // Rounded shape
                        ),
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Instruction Box
            Card(
               margin: const EdgeInsets.only(bottom: 20.0), // Margin below the card
               elevation: 1.0,
               shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Instruction box padding
                child: Text(
                  'Take photos, record audio, and add notes about the WASH asset. Once you have at least one photo or audio recording, you can save the inventory.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            // Photo Capture Section
            const Text(
              'Photo Capture',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) => _buildMediaSlot(index, _photoPaths[index], true)),
            ),
            const SizedBox(height: 16),
             ElevatedButton.icon(
              onPressed: _photoPaths.contains(null) ? () => _takePhoto(_photoPaths.indexOf(null)!) : null, // Only enabled if there's an empty slot
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                 backgroundColor: _photoPaths.contains(null) ? Colors.blue : Colors.grey, // Solid blue if active, grey if disabled
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                 ),
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            // Audio Recorder Section
            const Text(
              'Audio Recorder',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: List.generate(5, (index) => _buildMediaSlot(index, _audioPaths[index], false)),
            ),
             const SizedBox(height: 16),
             ElevatedButton.icon(
              onPressed: _isRecording ? _recordAudio : (_audioPaths.contains(null) ? _recordAudio : null), // Enable if recording or if there's an empty slot
              icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white),
              label: Text(_isRecording ? 'Stop Recording' : 'Record Audio', style: TextStyle(color: Colors.white)),
               style: ElevatedButton.styleFrom(
                 backgroundColor: _isRecording ? Colors.redAccent : (_audioPaths.contains(null) ? Colors.blue : Colors.grey), // Red if recording, solid blue if active, grey if disabled
                 foregroundColor: Colors.white,
                 shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                 ),
                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            // Notes Section
            const Text(
              'Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Enter notes here',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), // Border with rounded corners
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // Padding inside the text field
              ),
              maxLines: 4,
              keyboardType: TextInputType.multiline,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),
            // Spacer to ensure content is above bottom navigation bar
            SizedBox(height: kBottomNavigationBarHeight + 20), // Add space equivalent to bottom bar height + padding
          ],
        ),
      ),
       // BottomNavigationBar is in HomeScreen, not here
    );
  }
}