/// A single version entry in the app changelog.
///
/// Contains the version string, release date, and lists of new features
/// and bug fixes included in that release.
class ChangelogEntry {
  /// Semantic version string (e.g., '1.1.0').
  final String version;

  /// Release date in ISO format (e.g., '2026-03-20').
  final String date;

  /// List of new features or improvements in this version.
  final List<String> features;

  /// List of bug fixes in this version.
  final List<String> fixes;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.features,
    required this.fixes,
  });
}

/// Provides the static changelog data for all app versions.
///
/// Entries are ordered newest-first. The first entry should always
/// correspond to the current release version.
class ChangelogData {
  ChangelogData._();

  /// All changelog entries, newest first.
  static List<ChangelogEntry> get entries => const [
    ChangelogEntry(
      version: '1.1.0',
      date: '2026-03-20',
      features: [
        'Interactive tutorial for new players',
        'Hint system - stuck? Get a nudge!',
        'Achievement system with 15 badges',
        'Timed Challenge mode (Sprint, Marathon, Blitz)',
        'Level Packs with curated puzzles',
        'Level Editor - create and share your own puzzles',
        'Friends system with social leaderboards',
        'In-app store with cosmetics',
        'Analytics for better game experience',
      ],
      fixes: [
        'Improved performance on large grids',
        'Fixed daily challenge timezone handling',
      ],
    ),
    ChangelogEntry(
      version: '1.0.0',
      date: '2026-03-01',
      features: [
        'Initial release',
        'Hexagonal puzzle gameplay',
        'Daily challenges with leaderboards',
        'Multi-platform support',
      ],
      fixes: [],
    ),
  ];
}
