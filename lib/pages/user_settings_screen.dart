import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
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
  Uint8List? _imageBytes;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.user.displayName;
    if (widget.user.photoBase64 != null && widget.user.photoBase64!.isNotEmpty) {
      _imageBytes = base64Decode(widget.user.photoBase64!);
    }
  }

  void _saveSettings() async {
    String displayName = _displayNameController.text;

    widget.user.displayName = displayName;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (_imageBytes != null) {
      widget.user.photoBase64 = base64Encode(_imageBytes!);
    }
    await userProvider.updateUser(widget.user);

    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final img.Image originalImage = img.decodeImage(bytes)!;

      // Riduzione e compressione dell'immagine
      final img.Image resizedImage = img.copyResize(originalImage, width: 100); // Riduce l'immagine a 100px di larghezza
      final Uint8List compressedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 80)); // Compressione con qualit� 80

      setState(() {
        _imageBytes = compressedBytes;
      });
    }
  }

  ImageProvider _base64ToImageProvider(String base64String) {
    if (base64String.isEmpty) return AssetImage('assets/placeholder.png');
    Uint8List bytes = base64Decode(base64String);
    return MemoryImage(bytes);
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
            if (_imageBytes != null)
              CircleAvatar(
                radius: 40,
                backgroundImage: MemoryImage(_imageBytes!),
              )
            else if (widget.user.photoBase64 != null && widget.user.photoBase64!.isNotEmpty)
              CircleAvatar(
                radius: 40,
                backgroundImage: _base64ToImageProvider(widget.user.photoBase64!),
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
