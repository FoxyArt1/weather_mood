import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClothingGalleryPage extends StatefulWidget {
  const ClothingGalleryPage({super.key});

  @override
  State<ClothingGalleryPage> createState() => _ClothingGalleryPageState();
}

class _ClothingGalleryPageState extends State<ClothingGalleryPage> {
  late Future<List<Map<String, dynamic>>> _itemsFuture;

  final Map<String, Color> _tagColors = {
    'теплий': Colors.orange,
    'легкий': Colors.lightBlue,
    'спортивний': Colors.blueAccent,
    'строгий': Colors.brown,
    'зручний': Colors.green,
    'універсальний': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchClothingItems();
  }

  Future<List<Map<String, dynamic>>> _fetchClothingItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Користувач не авторизований');

    final querySnapshot = await FirebaseFirestore.instance
        .collection('clothes')
        .doc(user.uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Моя галерея одягу'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Помилка: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Галерея порожня'));
          }

          final items = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final tags = (item['tags'] ?? []) as List<dynamic>;

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          item['imageUrl'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            item['category'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: -8,
                            children: tags.map((tag) {
                              final tagText = tag.toString();
                              final color = _tagColors[tagText] ?? Colors.purple;
                              return Chip(
                                label: Text(tagText, style: const TextStyle(fontSize: 12)),
                                backgroundColor: color.withAlpha(40), // прозорий фон
                                labelStyle: const TextStyle(color: Colors.black87),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
