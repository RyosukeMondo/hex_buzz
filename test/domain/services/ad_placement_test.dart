import 'package:flutter_test/flutter_test.dart';
import 'package:hex_buzz/domain/services/ad_placement.dart';

void main() {
  group('AdPlacement', () {
    group('constants', () {
      test('levelsBeforeInterstitial is 3', () {
        expect(AdPlacement.levelsBeforeInterstitial, 3);
      });

      test('freeHintsPerDay is 3', () {
        expect(AdPlacement.freeHintsPerDay, 3);
      });

      test('hintAdCooldownSeconds is 60', () {
        expect(AdPlacement.hintAdCooldownSeconds, 60);
      });
    });

    group('shouldShowInterstitial', () {
      test('returns false for zero levels completed', () {
        expect(AdPlacement.shouldShowInterstitial(0), isFalse);
      });

      test('returns false for negative levels completed', () {
        expect(AdPlacement.shouldShowInterstitial(-1), isFalse);
      });

      test('returns false for 1 level completed', () {
        expect(AdPlacement.shouldShowInterstitial(1), isFalse);
      });

      test('returns false for 2 levels completed', () {
        expect(AdPlacement.shouldShowInterstitial(2), isFalse);
      });

      test('returns true for 3 levels completed', () {
        expect(AdPlacement.shouldShowInterstitial(3), isTrue);
      });

      test('returns false for 4 levels completed', () {
        expect(AdPlacement.shouldShowInterstitial(4), isFalse);
      });

      test('returns false for 5 levels completed', () {
        expect(AdPlacement.shouldShowInterstitial(5), isFalse);
      });

      test('returns true for 6 levels completed', () {
        expect(AdPlacement.shouldShowInterstitial(6), isTrue);
      });

      test('returns true for 9 levels completed', () {
        expect(AdPlacement.shouldShowInterstitial(9), isTrue);
      });

      test('returns true for 12 levels completed', () {
        expect(AdPlacement.shouldShowInterstitial(12), isTrue);
      });

      test('pattern repeats correctly for large numbers', () {
        expect(AdPlacement.shouldShowInterstitial(30), isTrue);
        expect(AdPlacement.shouldShowInterstitial(31), isFalse);
        expect(AdPlacement.shouldShowInterstitial(33), isTrue);
      });
    });

    group('canShowRewardedAd', () {
      test('returns true when lastAdTimestamp is null', () {
        expect(AdPlacement.canShowRewardedAd(null), isTrue);
      });

      test('returns false when less than cooldown seconds have passed', () {
        final recentTimestamp = DateTime.now().subtract(
          const Duration(seconds: 30),
        );
        expect(AdPlacement.canShowRewardedAd(recentTimestamp), isFalse);
      });

      test('returns true when exactly cooldown seconds have passed', () {
        final exactTimestamp = DateTime.now().subtract(
          const Duration(seconds: 60),
        );
        expect(AdPlacement.canShowRewardedAd(exactTimestamp), isTrue);
      });

      test('returns true when more than cooldown seconds have passed', () {
        final oldTimestamp = DateTime.now().subtract(
          const Duration(seconds: 120),
        );
        expect(AdPlacement.canShowRewardedAd(oldTimestamp), isTrue);
      });

      test('returns false when 1 second has passed', () {
        final veryRecent = DateTime.now().subtract(
          const Duration(seconds: 1),
        );
        expect(AdPlacement.canShowRewardedAd(veryRecent), isFalse);
      });

      test('returns true when a long time has passed', () {
        final longAgo = DateTime.now().subtract(
          const Duration(hours: 1),
        );
        expect(AdPlacement.canShowRewardedAd(longAgo), isTrue);
      });
    });

    group('hasRemainingFreeHints', () {
      test('returns true when 0 hints used today', () {
        expect(AdPlacement.hasRemainingFreeHints(0), isTrue);
      });

      test('returns true when 1 hint used today', () {
        expect(AdPlacement.hasRemainingFreeHints(1), isTrue);
      });

      test('returns true when 2 hints used today', () {
        expect(AdPlacement.hasRemainingFreeHints(2), isTrue);
      });

      test('returns false when 3 hints used today (limit reached)', () {
        expect(AdPlacement.hasRemainingFreeHints(3), isFalse);
      });

      test('returns false when more than 3 hints used today', () {
        expect(AdPlacement.hasRemainingFreeHints(4), isFalse);
        expect(AdPlacement.hasRemainingFreeHints(10), isFalse);
      });
    });
  });
}
