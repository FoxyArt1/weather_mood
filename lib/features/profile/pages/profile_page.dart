import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'clothing_gallery_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/avatar_placeholder.png'),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.add, size: 16),
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
