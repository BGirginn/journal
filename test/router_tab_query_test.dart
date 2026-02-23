import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/navigation/app_router.dart';

void main() {
  test('parses tab index from root query', () {
    final tab = parseRootTabFromUri(Uri.parse('/?tab=1'));
    expect(tab, 1);
  });

  test('invalid tab query falls back to home tab index', () {
    final tab = parseRootTabFromUri(Uri.parse('/?tab=not_a_number'));
    expect(tab, 2);
  });
}
