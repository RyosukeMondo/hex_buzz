import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Direct test of Firestore Flutter SDK to verify data parsing
/// Run with: dart run scripts/test_firestore_flutter.dart
void main() async {
  print('🔍 Testing Firestore Flutter SDK...\n');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyC-QprL7VkdoPr4QBmXmJ08OWxp-FblIGc',
        appId: '1:384062554696:web:hexbuzz',
        messagingSenderId: '384062554696',
        projectId: 'hexbuzz-game',
        authDomain: 'hexbuzz-game.firebaseapp.com',
        storageBucket: 'hexbuzz-game.appspot.com',
      ),
    );
    print('✅ Firebase initialized\n');

    final firestore = FirebaseFirestore.instance;
    final today = DateTime.now().toUtc();
    final dateStr =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    print('📅 Querying date: $dateStr');
    print('📡 Path: dailyChallenges/$dateStr\n');

    final doc = await firestore
        .collection('dailyChallenges')
        .doc(dateStr)
        .get();

    print('📄 Document exists: ${doc.exists}');

    if (doc.exists) {
      final data = doc.data()!;
      print('✅ Document data retrieved\n');
      print('📊 Top-level keys: ${data.keys.toList()}\n');

      final levelData = data['level'];
      print('🎮 Level data type: ${levelData.runtimeType}');
      if (levelData is Map) {
        print('🎮 Level keys: ${levelData.keys.toList()}\n');

        final cellsData = levelData['cells'];
        print('📦 Cells data type: ${cellsData.runtimeType}');
        if (cellsData is List && cellsData.isNotEmpty) {
          print('📦 First cell: ${cellsData[0]}');
          print('📦 First cell type: ${cellsData[0].runtimeType}');
        }

        final wallsData = levelData['walls'];
        print('\n🧱 Walls data type: ${wallsData.runtimeType}');
        if (wallsData is List && wallsData.isNotEmpty) {
          print('🧱 First wall: ${wallsData[0]}');
        }
      } else {
        print('❌ Level data is not a Map!');
      }
    } else {
      print('❌ Document does not exist');
    }
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace:\n$stackTrace');
  }
}
