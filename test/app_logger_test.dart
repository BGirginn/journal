import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/observability/app_logger.dart';

void main() {
  test('redacts sensitive values in log payload', () {
    final logger = AppLogger();
    final logs = <String>[];

    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        logs.add(message);
      }
    };
    addTearDown(() => debugPrint = previous);

    logger.info(
      'test_message',
      data: {
        'email': 'user@example.com',
        'token': 'secret-token',
        'nested': {'phone': '+9000000000', 'safe': 'ok'},
      },
    );

    expect(logs, isNotEmpty);
    final decoded = jsonDecode(logs.single) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final nested = data['nested'] as Map<String, dynamic>;

    expect(data['email'], equals('<redacted>'));
    expect(data['token'], equals('<redacted>'));
    expect(nested['phone'], equals('<redacted>'));
    expect(nested['safe'], equals('ok'));
  });
}
