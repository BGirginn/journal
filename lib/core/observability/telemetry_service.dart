import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:journal_app/core/observability/app_logger.dart';

final telemetryServiceProvider = Provider<TelemetryService>((ref) {
  final logger = ref.watch(appLoggerProvider);
  return TelemetryService(logger);
});

class TelemetryService {
  final AppLogger _logger;

  TelemetryService(this._logger);

  void track(
    String eventName, {
    Map<String, Object?> params = const {},
    int schemaVersion = 1,
  }) {
    _logger.info(
      'telemetry_event',
      data: {
        'event': eventName,
        'schema_version': schemaVersion,
        'params': params,
      },
    );
  }
}
