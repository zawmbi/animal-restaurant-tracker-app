// `ProgressTypes` and `UnlockedStore._defaultTypes` are two hand-maintained
// copies of the same list. Nothing in the app makes them agree, and when they
// disagreed the app wrote progress into a bucket nothing read.
//
// The companion check — that no *string literal* anywhere in lib/ names a
// bucket outside this list — cannot be done from inside Dart without reading
// the source tree, so it lives in scripts/qa_progress_buckets.py, which is
// runnable without a Flutter toolchain. Run both.

import 'package:flutter_test/flutter_test.dart';

import 'package:animal_restaurant_tracker/features/completion/data/completion_service.dart';
import 'package:animal_restaurant_tracker/features/completion/data/progress_types.dart';
import 'package:animal_restaurant_tracker/features/shared/data/unlocked_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bucket lists agree', () {
    test('registerOnStartup is a subset of the startup buckets', () {
      for (final bucket in ProgressTypes.registerOnStartup) {
        expect(
          UnlockedStore.startupBuckets,
          contains(bucket),
          reason: '"$bucket" is registered by CompletionService but is not '
              'loaded by UnlockedStore.init(), so the very first read after a '
              'relaunch answers false and the next write overwrites the saved '
              'set.',
        );
      }
    });

    test('every ProgressTypes bucket is a startup bucket', () {
      // registerOnStartup deliberately omits a few, but *every* constant is
      // counted by CompletionService, so every one has to load on startup.
      const all = <String>[
        ProgressTypes.customers,
        ProgressTypes.dish,
        ProgressTypes.letter,
        ProgressTypes.facility,
        ProgressTypes.courtyardFacility,
        ProgressTypes.mementoCollected,
        ProgressTypes.poster,
        ProgressTypes.movieAct,
        ProgressTypes.petOwned,
        ProgressTypes.petMature,
        ProgressTypes.petRoom,
        ProgressTypes.petPhotoTask,
        ProgressTypes.staffUnlocked,
        ProgressTypes.battlePassClaimed,
        ProgressTypes.battlePassPremium,
        ProgressTypes.acorn,
      ];
      for (final bucket in all) {
        expect(UnlockedStore.startupBuckets, contains(bucket),
            reason: '"$bucket" is counted but not loaded on startup');
      }
    });

    test('no bucket name is spelled two ways', () {
      final buckets = UnlockedStore.startupBuckets;
      expect(buckets.toSet().length, buckets.length,
          reason: 'duplicate entries in _defaultTypes: $buckets');
    });

    test('the plural/singular pairs the app actually writes are the plural '
        'ones', () {
      // Pages write 'customers' and 'facility'. 'customer' and
      // 'facility_purchased' are legacy spellings kept only so old saves load;
      // if a page ever goes back to them its progress becomes invisible to the
      // completion page.
      expect(ProgressTypes.customers, 'customers');
      expect(ProgressTypes.facility, 'facility');
      expect(UnlockedStore.startupBuckets, contains('customer'));
      expect(UnlockedStore.startupBuckets, contains('facility_purchased'));
    });
  });

  group('composite key shapes', () {
    test('battle pass claim key matches BattlePassDetailPage._claimKey', () {
      // BattlePassDetailPage builds 'bp:${pass.id}:$phaseId:$track:$exp'.
      // If these two ever diverge, every claimed tier stops counting.
      expect(
        CompletionService.battlePassClaimKey(
          passId: 'fantastical_party',
          phaseId: 'phase_1',
          track: 'normal',
          exp: 120,
        ),
        'bp:fantastical_party:phase_1:normal:120',
      );
      expect(
        CompletionService.battlePassClaimKey(
          passId: 'deep_sea_ballad',
          phaseId: 'phase_3',
          track: 'super',
          exp: 4000,
        ),
        'bp:deep_sea_ballad:phase_3:super:4000',
      );
    });

    test('acorn ids match AromaticAcornProgress._reqId / _taskId', () {
      expect(CompletionService.acornRequirementId('entrance', 0),
          'stage:entrance:req:0');
      expect(CompletionService.acornTaskId('entrance', 2),
          'stage:entrance:task:2');
    });

    test('requirement and task ids never collide for the same index', () {
      expect(CompletionService.acornRequirementId('1', 3),
          isNot(CompletionService.acornTaskId('1', 3)));
    });
  });

  group('memento source labels', () {
    test('slugs become titles', () {
      expect(CompletionService.prettyMementoSource('signature_store'),
          'Signature Store');
      expect(CompletionService.prettyMementoSource('customer_gift'),
          'Customer Gift');
    });

    test('a missing source is labelled, not blank', () {
      expect(CompletionService.prettyMementoSource(null), 'Other');
      expect(CompletionService.prettyMementoSource(''), 'Other');
      expect(CompletionService.prettyMementoSource('   '), 'Other');
    });

    test('no label leaks an underscore to the player', () {
      for (final raw in <String?>[
        'gachapon',
        'wishing_well',
        'mysterious_bird_nest',
        'redemption_code',
        null,
      ]) {
        expect(CompletionService.prettyMementoSource(raw), isNot(contains('_')));
      }
    });
  });
}
