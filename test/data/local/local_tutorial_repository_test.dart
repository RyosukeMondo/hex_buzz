import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/data/local/local_tutorial_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalTutorialRepository', () {
    late SharedPreferences prefs;
    late LocalTutorialRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repository = LocalTutorialRepository(prefs);
    });

    test('hasCompletedTutorial returns false by default', () {
      expect(repository.hasCompletedTutorial(), isFalse);
    });

    test('markCompleted sets tutorial as completed', () async {
      await repository.markCompleted();
      expect(repository.hasCompletedTutorial(), isTrue);
    });

    test('reset clears completed state', () async {
      await repository.markCompleted();
      expect(repository.hasCompletedTutorial(), isTrue);

      await repository.reset();
      expect(repository.hasCompletedTutorial(), isFalse);
    });

    test('persists completed state across instances', () async {
      await repository.markCompleted();

      // Create a new instance with the same prefs
      final repository2 = LocalTutorialRepository(prefs);
      expect(repository2.hasCompletedTutorial(), isTrue);
    });

    test('reset and re-check returns false', () async {
      await repository.markCompleted();
      await repository.reset();

      final repository2 = LocalTutorialRepository(prefs);
      expect(repository2.hasCompletedTutorial(), isFalse);
    });
  });
}
