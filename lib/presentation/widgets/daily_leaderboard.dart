import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/daily_challenge_completion.dart';
import '../../presentation/providers/auth_provider.dart';

/// Widget displaying the daily leaderboard for a specific challenge.
///
/// Queries and displays the top 50 completions from Firestore, ordered by
/// stars descending and completion time ascending. Highlights the current
/// user's position if they're in the leaderboard.
class DailyLeaderboard extends ConsumerWidget {
  final String dateId;

  const DailyLeaderboard({super.key, required this.dateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final currentUserId = authAsync.valueOrNull?.id;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dailyChallenges')
          .doc(dateId)
          .collection('completions')
          .orderBy('stars', descending: true)
          .orderBy('completionTimeMs', descending: false)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading leaderboard: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No completions yet. Be the first!',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Daily Leaderboard',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final completion = DailyChallengeCompletion.fromJson(data);
                  final rank = index + 1;
                  final isCurrentUser = completion.userId == currentUserId;

                  return _buildLeaderboardItem(
                    rank: rank,
                    completion: completion,
                    isCurrentUser: isCurrentUser,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardItem({
    required int rank,
    required DailyChallengeCompletion completion,
    required bool isCurrentUser,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? Colors.amber.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentUser
            ? Border.all(color: Colors.amber, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank with medal icons for top 3
          SizedBox(width: 40, child: _buildRankDisplay(rank)),

          const SizedBox(width: 12),

          // Username (using userId since username not available)
          Expanded(
            flex: 2,
            child: Text(
              'User ${completion.userId.substring(0, 8)}',
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Stars
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (index) => Icon(
                index < completion.stars ? Icons.star : Icons.star_border,
                size: 16,
                color: index < completion.stars ? Colors.amber : Colors.grey,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Time
          SizedBox(
            width: 60,
            child: Text(
              _formatTime(completion.completionTimeMs),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankDisplay(int rank) {
    String? emoji;

    switch (rank) {
      case 1:
        emoji = '🥇';
        break;
      case 2:
        emoji = '🥈';
        break;
      case 3:
        emoji = '🥉';
        break;
    }

    if (emoji != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 2),
          Text(
            '$rank',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Text(
      '#$rank',
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  String _formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final ms = (duration.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${ms.toString().padLeft(2, '0')}';
  }
}
