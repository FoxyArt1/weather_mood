import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'clothing_gallery_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final doc = await FirebaseFirestore.instance.collection('user').doc(user!.uid).get();
    setState(() {
      avatarUrl = doc.data()?['avatarUrl'];
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final storageRef = FirebaseStorage.instance.ref().child('avatars/${user!.uid}.jpg');

    await storageRef.putFile(file);
    final url = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance.collection('user').doc(user!.uid).update({
      'avatarUrl': url,
    });

    setState(() {
      avatarUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профіль')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Аватарка
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : const AssetImage('assets/avatar_placeholder.png') as ImageProvider,
                ),
                InkWell(
                  onTap: _pickAndUploadAvatar,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Email
            Text(
              user?.email ?? 'Користувач',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),

            // Кнопки
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Немає що вдягнути? Завантажуй фотографії!'),
              onPressed: () {
                Navigator.pushNamed(context, '/add-clothing');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Моя галерея одягу'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClothingGalleryPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
