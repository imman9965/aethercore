import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// 💡 HEALING ACTION: If you see an error here, you must implement
// a `RaidService` class with a `joinRaid({required String userId})`
// method in your lib folder, and import it here.
import 'package:aethercore/raid_service.dart';

void main() {
  group('Aether Raid Concurrency Integrity', () {
    late FakeFirebaseFirestore fakeFirestore;
    late RaidService raidService;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();

      try {
        raidService = RaidService(firestore: fakeFirestore);
      } catch (e) {
        fail(
            '💡 HEALING ACTION: Your RaidService must accept a firestore instance via constructor injection for testing.');
      }

      await fakeFirestore.collection('events').doc('dragon_raid').set({
        'slots_filled': 0,
        'max_slots': 15,
      });
    });

    test('Thundering Herd: 50 simultaneous join requests must strictly cap at 15',
        () async {
      List<Future<bool>> joinRequests = [];

      for (int i = 0; i < 50; i++) {
        try {
          joinRequests.add(raidService.joinRaid(userId: 'user_$i'));
        } catch (e) {
          fail(
              '💡 HEALING ACTION: joinRaid() crashed. Ensure it accepts a userId and returns a Future<bool>. Error: $e');
        }
      }

      final results = await Future.wait(joinRequests);
      final successfulJoins = results.where((result) => result == true).length;

      final snapshot =
          await fakeFirestore.collection('events').doc('dragon_raid').get();
      final slotsFilled = snapshot.data()?['slots_filled'] ?? 0;

      expect(successfulJoins, 15,
          reason:
              '💡 HEALING ACTION: Exactly 15 requests should report success (return true) to the client. The rest must gracefully return false.');
      expect(slotsFilled, 15,
          reason:
              '💡 HEALING ACTION: The database must record exactly 15 filled slots. If this is higher, your code suffers from a race condition. Use Transactions.');
    });
  });
}
