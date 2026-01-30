import 'dart:convert';
import 'package:http/http.dart' as http;

/// Direct test of Firestore REST API to verify challenge data is accessible
/// This bypasses the Flutter app entirely to isolate the issue
void main() async {
  print('🔍 Testing direct Firestore access via REST API...\n');

  final projectId = 'hexbuzz-game';
  final today = DateTime.now().toUtc();
  final dateStr =
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';

  print('📅 Date: $dateStr');
  print('🎯 Project: $projectId');
  print('📡 Querying: dailyChallenges/$dateStr\n');

  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/dailyChallenges/$dateStr',
  );

  try {
    final response = await http.get(url);
    print('📊 HTTP Status: ${response.statusCode}');
    print('📦 Response length: ${response.body.length} bytes\n');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ SUCCESS: Document exists!\n');
      print('📄 Document structure:');
      print(JsonEncoder.withIndent('  ').convert(data));
    } else if (response.statusCode == 404) {
      print('❌ Document not found (404)');
      print('Response: ${response.body}');
    } else {
      print('⚠️  Unexpected status code');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
