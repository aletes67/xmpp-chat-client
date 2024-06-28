import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_client/models/user.dart';

class UserSettingsScreen extends StatefulWidget {
  final User user;

  UserSettingsScreen({required this.user});

  @override
  _UserSettingsScreenState createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _displayNameController.text = widget.user.displayName;
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
    final password = _passwordController.text;
    final photoPath = _selectedImage?.path;

    widget.user.displayName = displayName;

    await _authService.saveUserProfile(widget.user, photoPath);
    if (password.isNotEmpty) {
      await _authService.saveCredentials(widget.user.username, password);
    }

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
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
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 100, width: 100)
                : (widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty)
                ? Image.network(widget.user.photoUrl!, height: 100, width: 100)
                : Container(height: 100, width: 100, color: Colors.grey),
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
