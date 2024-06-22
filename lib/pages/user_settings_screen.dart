import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class UserSettingsScreen extends StatefulWidget {
  @override
  _UserSettingsScreenState createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _resourceController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _selectedImage;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getUserProfile();
    setState(() {
      _displayNameController.text = profile['displayName'] ?? '';
      _resourceController.text = profile['resource'] ?? '';
      _photoPath = profile['photoPath'];
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _saveSettings() async {
    final displayName = _displayNameController.text;
    final resource = _resourceController.text;
    final password = _passwordController.text;
    final photoPath = _selectedImage?.path ?? _photoPath;

    await _authService.saveUserProfile(displayName, resource, photoPath!);
    if (password.isNotEmpty) {
      final credentials = await _authService.getCredentials();
      await _authService.saveCredentials(credentials['username']!, password);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _resourceController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(labelText: 'Display Name'),
            ),
            TextField(
              controller: _resourceController,
              decoration: InputDecoration(labelText: 'Resource'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 100, width: 100)
                : _photoPath != null
                ? Image.file(File(_photoPath!), height: 100, width: 100)
                : Container(),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
