import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/features/editor/engine/autosave_controller.dart';

void main() {
  test('debounces save calls', () {
    fakeAsync((async) {
      var saveCount = 0;
      final controller = AutosaveController(
        onSave: () async {
          saveCount++;
        },
      );

      controller.markDirty();
      controller.markDirty();
      async.elapse(
        const Duration(milliseconds: AutosaveController.debounceDurationMs - 1),
      );
      expect(saveCount, equals(0));

      async.elapse(const Duration(milliseconds: 2));
      async.flushMicrotasks();

      expect(saveCount, equals(1));
      expect(controller.state, equals(AutosaveState.saved));
    });
  });

  test('retries then succeeds', () {
    fakeAsync((async) {
      var attempts = 0;
      final controller = AutosaveController(
        onSave: () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('temporary');
          }
        },
      );

      controller.markDirty();

      async.elapse(const Duration(milliseconds: 1500));
      async.flushMicrotasks();
      expect(controller.state, equals(AutosaveState.dirty));

      async.elapse(const Duration(milliseconds: 1500));
      async.flushMicrotasks();
      expect(controller.state, equals(AutosaveState.dirty));

      async.elapse(const Duration(milliseconds: 3000));
      async.flushMicrotasks();

      expect(attempts, equals(3));
      expect(controller.state, equals(AutosaveState.saved));
    });
  });

  test('moves to error after max retries', () {
    fakeAsync((async) {
      var attempts = 0;
      final controller = AutosaveController(
        onSave: () async {
          attempts++;
          throw Exception('nope');
        },
      );

      controller.markDirty();
      async.elapse(const Duration(milliseconds: 1500));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1500));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 3000));
      async.flushMicrotasks();

      expect(attempts, equals(3));
      expect(controller.state, equals(AutosaveState.error));
      expect(controller.stateText, equals('Kaydetme hatası'));
    });
  });
}
