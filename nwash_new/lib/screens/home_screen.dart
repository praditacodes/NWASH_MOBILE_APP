import 'package:flutter/material.dart';
import './collect_data.dart';
import './history.dart';
import './settings.dart';
import '../services/connectivity_service.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/auth_provider.dart';
import '../services/local_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _initConnectivityListener();
  }

  // Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivityService.checkConnectivity();
    _isOnline = _connectivityService.isOnline(result);
    if (mounted) {
      setState(() {});
    }
  }

  // Listen to connectivity changes
  void _initConnectivityListener() {
    _connectivityService.onConnectivityChanged.listen((ConnectivityResult result) {
      final currentlyOnline = _connectivityService.isOnline(result);
      if (currentlyOnline != _isOnline && mounted) {
        setState(() {
          _isOnline = currentlyOnline;
        });
      }
    });
  }

  static List<Widget> _screens = <Widget>[
    CollectDataScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return Scaffold(
      appBar: AppBar(
        title: Text('NWASH'),
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
              if (!_isOnline) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.cloud_off, color: Colors.orange),
                );
              }
              if (syncProvider.pendingDataCount > 0) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload, color: Colors.blue),
                      SizedBox(width: 4),
                      Text('${syncProvider.pendingDataCount}', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Icon(Icons.cloud_done, color: Colors.green),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isOnline)
            Container(
              width: double.infinity,
              color: Colors.orange[100],
              padding: const EdgeInsets.all(8),
              child: Row(
                children: const [
                  Icon(Icons.wifi_off, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(child: Text('You are offline. Some features may be unavailable.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Collect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        onPressed: () {
          // Show quick capture options
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
      ) : null,
    );
  }
} 