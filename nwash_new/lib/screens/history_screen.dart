import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
// You might need to import your data session model if you want to display more details
// import '../models/data_session.dart';
import 'dart:convert'; // Required for jsonDecode if reading raw data

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _pendingSessions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPendingSessions();
  }

  Future<void> _loadPendingSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch pending data from SyncProvider
      // SyncProvider internally uses DataSyncService to get pending data
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      // Assuming getPendingData method is available and returns List<Map<String, dynamic>>
      final pendingData = await syncProvider._dataSyncService.getPendingData(); // Accessing private member for now
      // Note: It would be better to expose a public method in SyncProvider

      setState(() {
        _pendingSessions = pendingData;
      });
    } catch (e) {
      print('Error loading pending sessions: $e');
      // Optionally show an error message to the user
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper to parse and display session details
  Widget _buildSessionItem(Map<String, dynamic> sessionData) {
    // Safely access nested data
    final Map<String, dynamic> dataPayload = sessionData['data'] is Map ? Map<String, dynamic>.from(sessionData['data']) : {};
    final List<dynamic> mediaPaths = sessionData['mediaPaths'] is List ? sessionData['mediaPaths'] : [];
    final String notes = dataPayload['notes'] is String ? dataPayload['notes'] : '';
    final String timestampString = sessionData['timestamp'] is String ? sessionData['timestamp'] : 'Unknown Time';

    // Calculate photo and audio counts (basic assumption based on file extensions)
    int photoCount = mediaPaths.where((path) => path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')).length;
    int audioCount = mediaPaths.where((path) => path.endsWith('.mp3') || path.endsWith('.wav') || path.endsWith('.m4a')).length;
    bool hasNotes = notes.isNotEmpty;

    DateTime? timestamp;
    try {
      timestamp = DateTime.parse(timestampString);
    } catch (e) {
      timestamp = null; // Handle parsing error
    }

    String formattedTime = timestamp != null ? '${timestamp.month}/${timestamp.day}/${timestamp.year}, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}' : 'Invalid Date';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session on $formattedTime', // Display formatted timestamp
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Display Photo Count
                Row(
                  children: [
                    const Icon(Icons.photo, size: 18),
                    const SizedBox(width: 4),
                    Text('$photoCount Photos'),
                  ],
                ),
                // Display Audio Count
                Row(
                  children: [
                    const Icon(Icons.mic, size: 18),
                    const SizedBox(width: 4),
                    Text('$audioCount Recordings'),
                  ],
                ),
                // Display Notes Status
                Row(
                  children: [
                    Icon(hasNotes ? Icons.notes : Icons.note_alt_outlined, size: 18),
                    const SizedBox(width: 4),
                    Text(hasNotes ? 'Has Notes' : 'No Notes'),
                  ],
                ),
              ],
            ),
            // Add a play button if audio exists (optional)
            if (audioCount > 0)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.play_circle_fill),
                  onPressed: () {
                    // TODO: Implement audio playback
                    print('Play audio for session: $timestampString');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload History'), // Title from image
        automaticallyImplyLeading: false, // Hide back button
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadPendingSessions, // Disable when loading
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingSessions.isEmpty
              ? const Center(child: Text('No pending data to upload.'))
              : ListView.builder(
                  itemCount: _pendingSessions.length,
                  itemBuilder: (context, index) {
                    final session = _pendingSessions[index];
                    return _buildSessionItem(session);
                  },
                ),
    );
  }
} 