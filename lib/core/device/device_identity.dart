import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Shared preference key used for stable install-level device identity.
const syncDeviceIdKey = 'sync_device_id';

String getOrCreateSyncDeviceId(SharedPreferences prefs) {
  final existing = prefs.getString(syncDeviceIdKey);
  if (existing != null && existing.isNotEmpty) {
    return existing;
  }
  final created = const Uuid().v4();
  prefs.setString(syncDeviceIdKey, created);
  return created;
}
