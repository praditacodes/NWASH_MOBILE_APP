// FTP example screen is now disabled. All code commented out.
import 'package:flutter/material.dart';
import '../services/ftp_service.dart';

class FTPExampleScreen extends StatefulWidget {
  const FTPExampleScreen({super.key});

  @override
  State<FTPExampleScreen> createState() => _FTPExampleScreenState();
}

class _FTPExampleScreenState extends State<FTPExampleScreen> {
  // Controllers for text fields
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _portController = TextEditingController(text: '21');

  FTPService? _ftpService;
  bool _isConnected = false;
  List<String> _files = [];
  String _status = '';

  Future<void> _connectToFTP() async {
    // Create FTP service with user input
    _ftpService = FTPService(
      host: _hostController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      port: int.tryParse(_portController.text) ?? 21,
    );

    setState(() => _status = 'Connecting...');
    _isConnected = await _ftpService!.connect();
    setState(() => _status = _isConnected ? 'Connected' : 'Connection failed');
  }

  Future<void> _listFiles() async {
    if (!_isConnected || _ftpService == null) {
      setState(() => _status = 'Please connect first');
      return;
    }

    setState(() => _status = 'Listing files...');
    final files = await _ftpService!.listFiles('/');
    setState(() {
      _files = files;
      _status = 'Files listed successfully';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FTP Connection'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // FTP Server Details
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'FTP Host',
                hintText: 'e.g., ftp.example.com or 192.168.1.100',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your FTP username',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your FTP password',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: 'Usually 21',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            // Connect Button
            ElevatedButton(
              onPressed: _connectToFTP,
              child: Text(_isConnected ? 'Disconnect' : 'Connect to FTP'),
            ),
            const SizedBox(height: 16),
            
            // List Files Button
            ElevatedButton(
              onPressed: _listFiles,
              child: const Text('List Files'),
            ),
            const SizedBox(height: 16),
            
            // Status
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text('Status: $_status'),
            ),
            const SizedBox(height: 16),
            
            // File List
            if (_files.isNotEmpty) ...[
              const Text('Files on FTP Server:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_files[index]),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();
    super.dispose();
  }
} 