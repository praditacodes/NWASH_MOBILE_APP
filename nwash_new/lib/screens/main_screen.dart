import 'package:flutter/material.dart';
import 'collect_data.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NWASH Project'),
        actions: [
          // Show sync status
          Consumer<SyncProvider>(
            builder: (context, syncProvider, child) {
              if (syncProvider.isSyncing) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                );
              }
              return IconButton(
                icon: const Icon(Icons.sync),
                onPressed: syncProvider.isSyncing
                    ? null
                    : () async {
                        await syncProvider.syncData();
                      },
              );
            },
          ),
        ],
      ),
      body: const CollectDataScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show capture options
          showModalBottomSheet(
            context: context,
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to photo capture
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.mic),
                  title: const Text('Record Audio'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to audio recording
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.note_add),
                  title: const Text('Add Notes'),
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to notes
                  },
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 