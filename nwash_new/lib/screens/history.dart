import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import 'dart:io';
import '../services/local_storage_service.dart';
import '../models/data_session.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DataSession> _uploadedSessions = [];
  List<Map<String, dynamic>> _pendingSessions = [];
  List<DataSession> _draftSessions = [];
  bool _isLoading = false;
  bool _isOnline = false;

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final syncProvider = Provider.of<SyncProvider>(context, listen: false);
      _isOnline = syncProvider.isOnline;
      final pending = await syncProvider.getPendingData();
      final localStorage = LocalStorageService();
      final allSessions = await localStorage.getSessions();
      final uploaded = allSessions.where((s) => !s.draft && s.uploaded).toList();
      final drafts = allSessions.where((s) => s.draft).toList();
      uploaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      drafts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      setState(() {
        _pendingSessions = pending;
        _uploadedSessions = uploaded;
        _draftSessions = drafts;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() {
        _pendingSessions = [];
        _uploadedSessions = [];
        _draftSessions = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Widget _buildPendingSessionItem(Map<String, dynamic> sessionData) {
    final List<dynamic> mediaPaths = sessionData['mediaPaths'] is List ? sessionData['mediaPaths'] : [];
    final String notes = sessionData['data'] is Map && sessionData['data']['notes'] is String ? sessionData['data']['notes'] : '';
    final String timestampString = sessionData['timestamp'] is String ? sessionData['timestamp'] : 'Unknown Time';
    int photoCount = mediaPaths.where((path) => path.toString().toLowerCase().endsWith('.jpg') || path.toString().toLowerCase().endsWith('.jpeg') || path.toString().toLowerCase().endsWith('.png')).length;
    int audioCount = mediaPaths.where((path) => path.toString().toLowerCase().endsWith('.mp3') || path.toString().toLowerCase().endsWith('.wav') || path.toString().toLowerCase().endsWith('.m4a')).length;
    bool hasNotes = notes.isNotEmpty;
    DateTime? timestamp;
    try {
      timestamp = DateTime.parse(timestampString);
    } catch (e) {
      timestamp = null;
    }
    String formattedTime = timestamp != null ? '${timestamp.month}/${timestamp.day}/${timestamp.year}, ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}' : 'Invalid Date';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ListTile(
        title: Text('Pending Session on $formattedTime', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.photo, size: 16), SizedBox(width: 4), Text('$photoCount Photos'),
              SizedBox(width: 8), Icon(Icons.mic, size: 16), SizedBox(width: 4), Text('$audioCount Recordings'),
              SizedBox(width: 8), Icon(Icons.note, size: 16), SizedBox(width: 4), Text(hasNotes ? 'Has Notes' : 'No Notes'),
            ],
          ),
        ),
        trailing: Chip(label: Text('Pending'), backgroundColor: Colors.orange[100]),
      ),
    );
  }

  Widget _buildUploadedSessionItem(DataSession session) {
    final int photoCount = session.photos.length;
    final int audioCount = session.audios.length;
    final bool hasNotes = session.notes.isNotEmpty;
    final String formattedTime =
        '${session.timestamp.month}/${session.timestamp.day}/${session.timestamp.year}, '
        '${session.timestamp.hour}:${session.timestamp.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ListTile(
        title: Text('Uploaded Session on $formattedTime', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.photo, size: 16), SizedBox(width: 4), Text('$photoCount Photos'),
              SizedBox(width: 8), Icon(Icons.mic, size: 16), SizedBox(width: 4), Text('$audioCount Recordings'),
              SizedBox(width: 8), Icon(Icons.note, size: 16), SizedBox(width: 4), Text(hasNotes ? 'Has Notes' : 'No Notes'),
            ],
          ),
        ),
        trailing: Chip(label: Text('Uploaded'), backgroundColor: Colors.green[100]),
      ),
    );
  }

  Widget _buildDraftSessionItem(DataSession session) {
    final int photoCount = session.photos.length;
    final int audioCount = session.audios.length;
    final bool hasNotes = session.notes.isNotEmpty;
    final String formattedTime =
        '${session.timestamp.month}/${session.timestamp.day}/${session.timestamp.year}, '
        '${session.timestamp.hour}:${session.timestamp.minute.toString().padLeft(2, '0')}';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: ListTile(
        title: Text('Draft Session on $formattedTime', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.photo, size: 16), SizedBox(width: 4), Text('$photoCount Photos'),
              SizedBox(width: 8), Icon(Icons.mic, size: 16), SizedBox(width: 4), Text('$audioCount Recordings'),
              SizedBox(width: 8), Icon(Icons.note, size: 16), SizedBox(width: 4), Text(hasNotes ? 'Has Notes' : 'No Notes'),
            ],
          ),
        ),
        trailing: Chip(label: Text('Draft'), backgroundColor: Colors.grey[200]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSessions,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Now',
            onPressed: () async {
              await Provider.of<SyncProvider>(context, listen: false).syncData();
              await _loadSessions();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (_pendingSessions.isNotEmpty || _draftSessions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Pending Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                  ),
                  ..._draftSessions.map(_buildDraftSessionItem).toList(),
                  ..._pendingSessions.map(_buildPendingSessionItem).toList(),
                ],
                if (_isOnline && _uploadedSessions.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Uploaded Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[800])),
                  ),
                  ..._uploadedSessions.map(_buildUploadedSessionItem).toList(),
                ],
                if (_pendingSessions.isEmpty && _draftSessions.isEmpty && (!_isOnline || _uploadedSessions.isEmpty))
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No sessions found.')),
                  ),
              ],
            ),
    );
  }
}