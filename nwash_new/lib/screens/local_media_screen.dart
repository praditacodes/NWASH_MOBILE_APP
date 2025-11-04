import 'package:flutter/material.dart';
import 'dart:io';
import '../services/storage_service.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';

class LocalMediaScreen extends StatefulWidget {
  const LocalMediaScreen({Key? key}) : super(key: key);

  @override
  _LocalMediaScreenState createState() => _LocalMediaScreenState();
}

class _LocalMediaScreenState extends State<LocalMediaScreen> {
  List<File> _images = [];
  List<File> _audioFiles = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLocalMedia();
  }

  Future<void> _loadLocalMedia() async {
    setState(() => _isLoading = true);
    try {
      print('LocalMediaScreen: Attempting to load local images and audio...');
      final images = await StorageService.getStoredImages();
      final audioFiles = await StorageService.getStoredAudioFiles();
      print('LocalMediaScreen: Loaded ${images.length} images and ${audioFiles.length} audio files.');
      setState(() {
        _images = images;
        _audioFiles = audioFiles;
        _isLoading = false;
      });
    } catch (e) {
      print('LocalMediaScreen: Error loading local media: $e');
      setState(() => _isLoading = false);
    }
  }

  void _deleteFile(File file) async {
    try {
      await StorageService.deleteFile(file.path);
      await _loadLocalMedia(); // Reload the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Local Media'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Images'),
              Tab(text: 'Audio'),
            ],
          ),
          actions: [
            // Sync button
            Consumer<SyncProvider>(
              builder: (context, syncProvider, child) {
                return IconButton(
                  icon: const Icon(Icons.sync),
                  onPressed: syncProvider.isSyncing
                      ? null
                      : () async {
                          await syncProvider.syncData();
                          await _loadLocalMedia();
                        },
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // Images Tab
                  _images.isEmpty
                      ? const Center(child: Text('No images found'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            final image = _images[index];
                            return GestureDetector(
                              onTap: () => _showImageDialog(image),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.file(
                                      image,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteFile(image),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  // Audio Tab
                  _audioFiles.isEmpty
                      ? const Center(child: Text('No audio files found'))
                      : ListView.builder(
                          itemCount: _audioFiles.length,
                          itemBuilder: (context, index) {
                            final audioFile = _audioFiles[index];
                            return ListTile(
                              title: Text(path.basename(audioFile.path)),
                              subtitle: FutureBuilder<int>(
                                future: StorageService.getFileSize(audioFile.path),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return Text(StorageService.formatFileSize(snapshot.data!));
                                  }
                                  return const Text('Loading...');
                                },
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: () {
                                      // TODO: Implement audio playback
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteFile(audioFile),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
      ),
    );
  }

  void _showImageDialog(File image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(image),
            ButtonBar(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteFile(image);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 