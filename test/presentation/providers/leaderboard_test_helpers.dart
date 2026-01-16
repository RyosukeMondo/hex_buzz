import 'package:hex_buzz/domain/models/leaderboard_entry.dart';
import 'package:hex_buzz/domain/services/leaderboard_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockLeaderboardRepository extends Mock implements LeaderboardRepository {}

final testLeaderboardEntries = [
  LeaderboardEntry(
    userId: 'user1',
    username: 'Player1',
    totalStars: 100,
    rank: 1,
    updatedAt: DateTime(2024, 1, 1),
  ),
  LeaderboardEntry(
    userId: 'user2',
    username: 'Player2',
    totalStars: 90,
    rank: 2,
    updatedAt: DateTime(2024, 1, 1),
  ),
  LeaderboardEntry(
    userId: 'user3',
    username: 'Player3',
    totalStars: 80,
    rank: 3,
    updatedAt: DateTime(2024, 1, 1),
  ),
];

final testUserEntry = LeaderboardEntry(
  userId: 'current-user',
  username: 'CurrentUser',
  totalStars: 75,
  rank: 5,
  updatedAt: DateTime(2024, 1, 1),
);
