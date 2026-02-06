import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/sync/hlc.dart';

void main() {
  group('Hlc', () {
    test('parses correctly', () {
      final hlc = Hlc.parse('1672531200000:0001:deviceA');
      expect(hlc.millis, 1672531200000);
      expect(hlc.counter, 1);
      expect(hlc.nodeId, 'deviceA');
    });

    test('toString formats correctly', () {
      const hlc = Hlc(1000, 5, 'node1');
      expect(hlc.toString(), '1000:0005:node1');
    });

    test('comparison logic', () {
      const t1 = Hlc(1000, 0, 'a');
      const t2 = Hlc(1000, 1, 'a');
      const t3 = Hlc(1001, 0, 'a');
      const t4 = Hlc(1000, 0, 'b');

      expect(t1 < t2, true);
      expect(t2 < t3, true);
      expect(t1 < t4, true); // node id tie breaker
    });

    test('send (local event)', () {
      const local = Hlc(1000, 0, 'node1');

      // Case 1: Wall time moved forward
      // 1000:0000 -> 1010:0000
      final next1 = local.send(1010);
      expect(next1.millis, 1010);
      expect(next1.counter, 0);

      // Case 2: Wall time stuck (burst of events)
      // 1000:0000 -> 1000:0001
      final next2 = local.send(1000);
      expect(next2.millis, 1000);
      expect(next2.counter, 1);

      // Case 3: Wall time backwards (clock skew)
      // 1000:0000 -> 1000:0001 (ignores physical regression)
      final next3 = local.send(990);
      expect(next3.millis, 1000);
      expect(next3.counter, 1);
    });

    test('receive (remote event)', () {
      const local = Hlc(1000, 2, 'localIdx');

      // Case 1: Remote is old. Physical time is new.
      // Remote: 900:0, Physical: 1010
      // Result: 1010:0 (driven by physical)
      final res1 = local.receive(const Hlc(900, 0, 'remote'), 1010);
      expect(res1.millis, 1010);
      expect(res1.counter, 0);

      // Case 2: Remote is ahead of physical and local.
      // Remote: 1100:5, Physical: 1010
      // Result: 1100:6 (catch up to remote)
      final res2 = local.receive(const Hlc(1100, 5, 'remote'), 1010);
      expect(res2.millis, 1100);
      expect(res2.counter, 6);

      // Case 3: Remote same millis but higher counter
      // Local: 1000:2, Remote: 1000:5, Physical: 1000
      // Result: 1000:6
      final res3 = local.receive(const Hlc(1000, 5, 'remote'), 1000);
      expect(res3.millis, 1000);
      expect(res3.counter, 6);
    });
  });
}
