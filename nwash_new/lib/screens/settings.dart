import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/local_storage_service.dart';
import '../services/api_service.dart';
import '../main.dart'; // Import ThemeProvider

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.name);
    _phoneController = TextEditingController(text: provider.phone);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<SettingsProvider>(context);
    _nameController.text = provider.name;
    _phoneController.text = provider.phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SettingsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blue header card
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Settings',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            SizedBox(height: 16),
            // User Information Card
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('User Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text('Name'),
                  SizedBox(height: 4),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      border: OutlineInputBorder(),
                    ),
                    controller: _nameController,
                    onChanged: provider.updateName,
                  ),
                  SizedBox(height: 16),
                  Text('Phone Number'),
                  SizedBox(height: 4),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Enter your phone number',
                      border: OutlineInputBorder(),
                    ),
                    controller: _phoneController,
                    onChanged: provider.updatePhone,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  Text('User ID'),
                  SizedBox(height: 4),
                  TextField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: provider.userId),
                    enabled: false,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Automatically generated, cannot be changed.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await provider.updateName(_nameController.text);
                      await provider.updatePhone(_phoneController.text);
                      // Update controllers to reflect saved values
                      _nameController.text = provider.name;
                      _phoneController.text = provider.phone;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('User information saved!')),
                      );
                    },
                    icon: Icon(Icons.save),
                    label: Text('Save User Information'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
            // About Card
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('WASH Asset Data Collection App v1.0.0'),
                  Text('© 2025 WASH Asset Management'),
                ],
              ),
            ),
            // Logout Button
            SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Confirm Logout'),
                      content: Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Logout'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    Provider.of<SettingsProvider>(context, listen: false).clearUserInfo();
                    await Provider.of<AuthProvider>(context, listen: false).signOut(context);
                    final userEmail = await ApiService.getEmail();
                    if (userEmail != null) {
                      await LocalStorageService.clearAllStatic(userEmail);
                    }
                    if (Navigator.canPop(context)) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ),
            SizedBox(height: 32),
            // Dark mode toggle
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  title: Text('Dark Mode'),
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    themeProvider.toggleTheme(val);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}