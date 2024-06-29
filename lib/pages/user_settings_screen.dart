import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:chat_client/services/auth_service.dart';
import 'package:chat_client/models/user.dart';
import '../providers/user_provider.dart';

class UserSettingsScreen extends StatefulWidget {
  final User user;

  UserSettingsScreen({required this.user});

  @override
  _UserSettingsScreenState createState() => _UserSettingsScreenState();
}

class _UserSettingsScreenState extends State<UserSettingsScreen> {
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.user.displayName;
    if (widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty) {
      _image = File(widget.user.photoUrl!);
    }
  }

  void _saveSettings() async {
    String displayName = _displayNameController.text;

    widget.user.displayName = displayName;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (_image != null) {
      await userProvider.updateUser(widget.user, _image!.path);
    } else {
      await userProvider.updateUser(widget.user, null);
    }

    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
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
            if (_image != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: FileImage(_image!),
              )
            else if (widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty)
              CircleAvatar(
                radius: 40,
                backgroundImage: FileImage(File(widget.user.photoUrl!)),
              )
            else
              CircleAvatar(
                radius: 40,
                child: Text(widget.user.displayName.isNotEmpty
                    ? widget.user.displayName[0]
                    : '?'),
              ),
            SizedBox(height: 20),
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(labelText: 'Display Name'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
