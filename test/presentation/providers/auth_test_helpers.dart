import 'package:hex_buzz/domain/models/user.dart';
import 'package:hex_buzz/domain/services/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

final testUser = User(
  id: 'test-id',
  username: 'testuser',
  createdAt: DateTime(2024, 1, 1),
  isGuest: false,
);

final guestUser = User(
  id: 'guest',
  username: 'Guest',
  createdAt: DateTime(2024, 1, 1),
  isGuest: true,
);
