/// Immutable container for all user-facing strings in the app.
///
/// Each supported locale provides a const instance of this class.
/// All fields are required to ensure complete translations.
class AppStrings {
  // Front screen
  final String appTitle;
  final String tapToStart;
  final String onePathChallenge;

  // Auth
  final String playAsGuest;
  final String signInWithGoogle;
  final String loginTitle;

  // Level select
  final String dailyChallenge;
  final String levelPacks;
  final String timedChallenge;
  final String achievements;
  final String friends;
  final String create;
  final String store;
  final String settings;

  // Game
  final String levelComplete;
  final String nextLevel;
  final String replay;
  final String levels;
  final String progress;
  final String retry;
  final String hint;
  final String noHintsRemaining;
  final String viewLeaderboard;
  final String time;

  // Timed challenge
  final String timesUp;
  final String puzzlesSolved;
  final String bestStreak;
  final String averageTime;
  final String playAgain;
  final String backToMenu;
  final String sprint;
  final String marathon;
  final String blitz;

  // Settings
  final String soundEffects;
  final String visualEffects;
  final String notifications;
  final String theme;
  final String aboutApp;
  final String whatsNew;
  final String rateApp;
  final String privacyPolicy;
  final String termsOfService;
  final String language;

  // Common
  final String ok;
  final String cancel;
  final String save;
  final String delete;
  final String share;
  final String back;
  final String loading;
  final String error;

  const AppStrings({
    required this.appTitle,
    required this.tapToStart,
    required this.onePathChallenge,
    required this.playAsGuest,
    required this.signInWithGoogle,
    required this.loginTitle,
    required this.dailyChallenge,
    required this.levelPacks,
    required this.timedChallenge,
    required this.achievements,
    required this.friends,
    required this.create,
    required this.store,
    required this.settings,
    required this.levelComplete,
    required this.nextLevel,
    required this.replay,
    required this.levels,
    required this.progress,
    required this.retry,
    required this.hint,
    required this.noHintsRemaining,
    required this.viewLeaderboard,
    required this.time,
    required this.timesUp,
    required this.puzzlesSolved,
    required this.bestStreak,
    required this.averageTime,
    required this.playAgain,
    required this.backToMenu,
    required this.sprint, required this.marathon, required this.blitz,
    required this.soundEffects,
    required this.visualEffects,
    required this.notifications,
    required this.theme,
    required this.aboutApp,
    required this.whatsNew,
    required this.rateApp,
    required this.privacyPolicy,
    required this.termsOfService,
    required this.language,
    required this.ok, required this.cancel,
    required this.save, required this.delete,
    required this.share, required this.back,
    required this.loading,
    required this.error,
  });
}
