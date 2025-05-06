import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:weather_mood/services/weather_service.dart';
import 'package:weather_mood/features/recommendation/recommendation_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _allItems = []; // усі речі юзера
  List<Map<String, dynamic>>? _recommendedItems;
  late Future<Map<String, dynamic>> _weatherFuture;
  bool _showMoodDialog = false;
  bool _showLookUI = false;
  Map<String, int> _categoryIndexes = {};


  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': 'Радісний'},
    {'emoji': '😐', 'label': 'Спокійний'},
    {'emoji': '😢', 'label': 'Сумний'},
    {'emoji': '😤', 'label': 'Злий'},
    {'emoji': '😴', 'label': 'Втомлений'},
    {'emoji': '🤩', 'label': 'Натхнений'},
  ];

  String? _aiExplanation;

  void _generateAiExplanation(Map<String, dynamic> weather) {
    if (_recommendedItems == null || _recommendedItems!.isEmpty) return;

    final temp = weather['temp']?.toStringAsFixed(0) ?? '?';
    final desc = weather['description'] ?? 'незрозуміла погода';
    final mood = _selectedMood ?? 'невідомий настрій';

    final List<String> keywords = [];

    for (var item in _recommendedItems!) {
      final tags = item['tags'];
      if (tags != null && tags is List) {
        keywords.addAll(tags.map((e) => e.toString()));
      }
    }

    final tagSummary = keywords.toSet().join(', ');

    _aiExplanation =
    'Я обрав цей лук, бо сьогодні $desc і температура $temp°C. '
        'Ці речі мають такі властивості: $tagSummary. '
        'Вони чудово пасують до твого настрою: $mood.';
  }


  String? _selectedMood;

  @override
  void initState() {
    super.initState();
    _weatherFuture = _checkLocationPermissionAndFetchWeather();

    final user = FirebaseAuth.instance.currentUser;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Привіт, ${user.email}!'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
        _checkIfNeedMood();
      }
    });
  }

  void _checkIfNeedMood() {
    setState(() => _showMoodDialog = true);
  }

  Future<void> _showMoodSelectionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Який у тебе настрій?'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _moods.map((mood) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _selectedMood = mood['label']!;
                  _showLookUI = true;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(mood['emoji']!, style: const TextStyle(fontSize: 36)),
                  Text(mood['label']!),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _generateLook() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedMood == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('clothes')
        .doc(user.uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .get();

    final items = querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    _allItems = items; // зберігаємо всі речі юзера
    _categoryIndexes.clear();
    for (var category in ['Голова', 'Тіло', 'Ноги', 'Ступні', 'Аксесуари']) {
      _categoryIndexes[category] = 0;
    }


    final weather = await WeatherService.fetchWeatherByLocation(
      latitude: 50.4501,
      longitude: 30.5234,
    );

    final recommended = await RecommendationService.generateLookFromItems(
      items: items,
      mood: _selectedMood!,
      weather: weather['main'] ?? '',
    );
    _allItems = items;
    _categoryIndexes.clear();
    for (var item in recommended) {
      final category = item['category'];
      _categoryIndexes[category] = 0;
    }

    if (!context.mounted) return;
    setState(() {
      _recommendedItems = recommended;
    });
    _generateAiExplanation(weather);
    _categoryIndexes.clear();
    for (var item in recommended) {
      final category = item['category'];
      _categoryIndexes[category] = 0;
    }


  }

  Future<Map<String, dynamic>> _checkLocationPermissionAndFetchWeather() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationDialog(
        title: 'Служба геолокації вимкнена',
        message: 'Будь ласка, увімкніть GPS у налаштуваннях пристрою.',
      );
      throw Exception('GPS вимкнено');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await _showLocationDialog(
          title: 'Доступ до геолокації відхилено',
          message: 'Надайте доступ до геопозиції, щоб ми могли показати погоду.',
        );
        throw Exception('Геолокацію відхилено');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showLocationDialog(
        title: 'Доступ до геолокації заблокований',
        message: 'Відкрий налаштування → Додатки → Дозволи → Геолокація.',
      );
      throw Exception('Геолокація заблокована назавжди');
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Таймаут: не отримано координати'),
      );

      return await WeatherService.fetchWeatherByLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      debugPrint('⚠️ Геолокація не вдалася: $e\n➡️ Використовуємо Київ');
      return await WeatherService.fetchWeatherByLocation(
        latitude: 50.4501,
        longitude: 30.5234,
      );
    }
  }

  Future<void> _showLocationDialog({
    required String title,
    required String message,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }

  Widget _buildLookCategory(String label, String category) {
    final categoryItems = _allItems.where((item) => item['category'] == category).toList();
    final currentIndex = _categoryIndexes[category] ?? 0;

    if (categoryItems.isEmpty) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back_ios, color: Colors.grey),
              _buildImageBox(null),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
        ],
      );
    }

    final currentItem = categoryItems[currentIndex];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () {
                setState(() {
                  _categoryIndexes[category] =
                      (currentIndex - 1 + categoryItems.length) % categoryItems.length;
                });
              },
            ),
            _buildImageBox(currentItem['imageUrl']),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {
                setState(() {
                  _categoryIndexes[category] =
                      (currentIndex + 1) % categoryItems.length;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
      ],
    );
  }
  Widget _buildImageBox(String? imageUrl) {
    return Container(
      width: 80,
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: imageUrl != null
          ? Image.network(imageUrl, fit: BoxFit.cover)
          : const Center(child: Text('❌\nНемає', textAlign: TextAlign.center)),
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_showMoodDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _showMoodSelectionDialog();
        setState(() => _showMoodDialog = false);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Головна'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _weatherFuture = _checkLocationPermissionAndFetchWeather()),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _weatherFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Помилка: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Немає даних про погоду'));
            }

            final weather = snapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Column(
                    children: [
                      Image.network("https://openweathermap.org/img/wn/${weather['icon']}@2x.png", width: 100, height: 100),
                      const SizedBox(height: 8),
                      Text(
                        '${weather['temp'].toStringAsFixed(1)}°C',
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(weather['description'], style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 8),
                      Text('Місто: ${weather['city'] ?? 'Невідомо'}', style: const TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_showLookUI && _recommendedItems == null)
                  ElevatedButton(
                    onPressed: _generateLook,
                    child: const Text('Згенерувати лук'),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  switchInCurve: Curves.easeIn,
                  switchOutCurve: Curves.easeOut,
                  child: _recommendedItems != null
                      ? Column(
                    key: ValueKey(_recommendedItems.hashCode), // важливо!
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      const Text(
                        'Згенерований лук:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _buildLookCategory('Голова', 'Голова'),
                      _buildLookCategory('Тіло', 'Тіло'),
                      _buildLookCategory('Ноги', 'Ноги'),
                      _buildLookCategory('Ступні', 'Ступні'),
                      const Divider(thickness: 1.5, height: 32),
                      _buildLookCategory('Аксесуари', 'Аксесуари'),
                      const SizedBox(height: 24),
                      if (_aiExplanation != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Text(
                            '🤖 ШІ: $_aiExplanation',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Згенерувати ще раз'),
                          onPressed: _generateLook,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
