// Run: dart run scripts/seed_data.dart
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:jerrypizza/firebase_options.dart';

Future<void> main() async {
  print('🔥 Starting seed...');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = FirebaseFirestore.instance;

  final file = File('assets/menu.json');

  if (!file.existsSync()) {
    print('❌ File not found: assets/menu.json');
    return;
  }

  final jsonData = json.decode(await file.readAsString());
  print('📄 JSON loaded');

  for (final col in ['categories', 'products', 'deals']) {
    final old = await db.collection(col).get();
    for (final doc in old.docs) {
      await doc.reference.delete();
    }
    print('🗑️ Cleared: $col');
  }

  final categories = jsonData['categories'] as List;
  final catIdMap = <String, String>{};

  for (var i = 0; i < categories.length; i++) {
    final cat = categories[i];
    final ref = await db.collection('categories').add({
      'name': cat['name'] ?? '',
      'imageUrl': cat['imageUrl'] ?? '',
      'imagePath': cat['imagePath'] ?? '',
      'order': i + 1,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    catIdMap[cat['id'] as String] = ref.id;
    print('✅ Category: ${cat['name']}');
  }

  final items = jsonData['items'] as List;

  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final variants = (item['variants'] as List)
        .map((v) => {
              'name': v['label'] ?? '',
              'price': (v['price'] as num).toDouble(),
            })
        .toList();

    final catId = item['category'] as String;
    final catName = categories
        .firstWhere((c) => c['id'] == catId, orElse: () => {'name': ''})['name'];

    await db.collection('products').add({
      'name': item['name'] ?? '',
      'description': item['description'] ?? '',
      'imageUrl': item['imageUrl'] ?? '',
      'imagePath': item['imagePath'] ?? '',
      'categoryId': catIdMap[catId] ?? '',
      'categoryName': catName,
      'basePrice': variants.isNotEmpty ? variants.first['price'] : 0,
      'sizes': variants,
      'addons': [],
      'mealOptions': [],
      'relatedProductIds': [],
      'isAvailable': true,
      'isPopular': i < 8,
      'order': i,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print('✅ Product: ${item['name']}');
  }

  final deals = jsonData['deals'] as List;

  for (var i = 0; i < deals.length; i++) {
    final deal = deals[i];
    await db.collection('deals').add({
      'title': deal['title'] ?? '',
      'description': (deal['contents'] as List).join(' + '),
      'imageUrl': deal['imageUrl'] ?? '',
      'imagePath': deal['imagePath'] ?? '',
      'price': (deal['price'] as num).toDouble(),
      'originalPrice': 0,
      'items': deal['contents'],
      'isActive': true,
      'order': i,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('✅ Deal: ${deal['title']}');
  }

  await db.collection('settings').doc('app').set({
    'deliveryFee': 100,
    'minOrder': 700,
    'freeDelivery': 1500,
    'isOpen': true,
    'contactNumber': '0314-3636434',
    'whatsappNumber': '03259869056',
    'restaurantAddress': 'Pakpattan Chowk, Sahiwal',
    'holidayMode': false,
    'holidayReason': '',
    'businessHours': {
      'monday': {'open': '11:00', 'close': '23:00', 'isOpen': true},
      'tuesday': {'open': '11:00', 'close': '23:00', 'isOpen': true},
      'wednesday': {'open': '11:00', 'close': '23:00', 'isOpen': true},
      'thursday': {'open': '11:00', 'close': '23:00', 'isOpen': true},
      'friday': {'open': '14:00', 'close': '23:00', 'isOpen': true},
      'saturday': {'open': '11:00', 'close': '23:00', 'isOpen': true},
      'sunday': {'open': '11:00', 'close': '23:00', 'isOpen': true},
    },
  });
  print('✅ Settings added');

  print('');
  print('🎉 Seed complete!');
  print('📊 Categories: ${categories.length}');
  print('📦 Products: ${items.length}');
  print('🎁 Deals: ${deals.length}');
}