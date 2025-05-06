import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AddClothingPage extends StatefulWidget {
  const AddClothingPage({super.key});

  @override
  State<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends State<AddClothingPage> {
  File? _imageFile;
  final _nameController = TextEditingController();
  String? _selectedCategory;
  final List<String> _selectedTags = [];
  bool _isLoading = false;

  final List<String> _categories = [
    'Голова',
    'Обличчя',
    'Шия',
    'Тіло',
    'Руки',
    'Пояс',
    'Ноги',
    'Ступні',
    'Аксесуари'
  ];

  final List<String> _tags = [
    'теплий',
    'легкий',
    'спортивний',
    'строгий',
    'зручний',
    'універсальний'
  ];

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _saveClothingItem() async {
    final enteredCategory = _isCustomCategory
        ? _customCategoryController.text.trim()
        : _selectedCategory;

    if (_imageFile == null || _nameController.text.isEmpty || enteredCategory == null || enteredCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Будь ласка, заповніть усі поля')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Користувач не авторизований');

      final processedImage = await _removeBackground(_imageFile!);
      if (processedImage == null || !processedImage.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Оброблений файл не знайдено')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final imageUrl = await _uploadToCloudinary(processedImage);
      if (imageUrl == null) throw Exception('Не вдалося завантажити зображення');

      await FirebaseFirestore.instance
          .collection('clothes')
          .doc(user.uid)
          .collection('items')
          .add({
        'name': _nameController.text,
        'category': enteredCategory,
        'tags': _selectedTags,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Одяг успішно додано!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Помилка при збереженні: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }


  Future<File?> _removeBackground(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.remove.bg/v1.0/removebg'),
    )
      ..headers['X-Api-Key'] = 'CVghkAGZQTHJzvnNA5TU2ecp'
      ..files.add(await http.MultipartFile.fromPath('image_file', imageFile.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final bytes = await response.stream.toBytes();
      final tempDir = Directory.systemTemp;
      final processed = await File('${tempDir.path}/no_bg_${DateTime.now().millisecondsSinceEpoch}.png')
          .writeAsBytes(bytes);
      return processed;
    } else {
      print('❌ Remove.bg помилка: ${response.statusCode}');
      return null;
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    const cloudName = 'dzeu8vz2b';
    const uploadPreset = 'unsigned_preset';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', 'png'),
      ));


    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(responseBody);
        return jsonData['secure_url'];
      } else {
        print('❌ Cloudinary upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Виняток Cloudinary: $e');
      return null;
    }
  }
// Додати перед build()
  final _customCategoryController = TextEditingController();
  bool _isCustomCategory = false;
  final _customTagController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Додати одяг')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _imageFile != null
                  ? Image.file(_imageFile!, height: 200)
                  : Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey[300],
                child: const Icon(Icons.add_a_photo, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Назва одягу',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

// Категорія з можливістю додавання
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: [
                ..._categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                const DropdownMenuItem(value: 'custom', child: Text('Інше (додати свою категорію)')),
              ],
              onChanged: (val) {
                setState(() {
                  if (val == 'custom') {
                    _isCustomCategory = true;
                    _selectedCategory = null;
                  } else {
                    _isCustomCategory = false;
                    _selectedCategory = val;
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Категорія',
                border: OutlineInputBorder(),
              ),
            ),
            if (_isCustomCategory)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _customCategoryController,
                  decoration: const InputDecoration(
                    labelText: 'Власна категорія',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

            const SizedBox(height: 24),

// Теги з чекбоксами
            const Text('Теги', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),

// Додавання нового тегу
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTagController,
                    decoration: const InputDecoration(
                      labelText: 'Новий тег',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final newTag = _customTagController.text.trim();
                    if (newTag.isNotEmpty && !_tags.contains(newTag)) {
                      setState(() {
                        _tags.add(newTag);
                        _selectedTags.add(newTag);
                        _customTagController.clear();
                      });
                    }
                  },
                  child: const Text('Додати'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _saveClothingItem,
              child: const Text('Зберегти'),
            ),
          ],
        ),
      ),
    );
  }
}