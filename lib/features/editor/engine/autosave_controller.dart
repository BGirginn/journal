import 'dart:async';
import 'package:flutter/foundation.dart';

/// Autosave controller with debouncing
/// Saves after 1500ms of inactivity or immediately on gesture end
class AutosaveController extends ChangeNotifier {
  /// Debounce duration in milliseconds
  static const int debounceDurationMs = 1500;

  /// Current save state
  AutosaveState _state = AutosaveState.saved;
  AutosaveState get state => _state;

  /// Timer for debounced saves
  Timer? _debounceTimer;

  /// Callback to perform the actual save
  final Future<void> Function() onSave;

  /// Last save timestamp
  DateTime? _lastSaveTime;
  DateTime? get lastSaveTime => _lastSaveTime;

  /// Whether a save is in progress
  bool _isSaving = false;
  bool get isSaving => _isSaving;

  /// Pending save after current one completes
  bool _pendingSave = false;

  AutosaveController({required this.onSave});

  /// Mark content as dirty (modified)
  /// Starts the debounce timer
  void markDirty() {
    if (_state == AutosaveState.saving) {
      _pendingSave = true;
      return;
    }

    _state = AutosaveState.dirty;
    notifyListeners();

    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: debounceDurationMs),
      () => _performSave(),
    );
  }

  /// Immediately flush pending changes (e.g., on gesture end)
  Future<void> flushNow() async {
    _debounceTimer?.cancel();

    if (_state == AutosaveState.dirty || _pendingSave) {
      await _performSave();
    }
  }

  /// Perform the actual save
  Future<void> _performSave() async {
    if (_isSaving) {
      _pendingSave = true;
      return;
    }

    if (_state == AutosaveState.saved && !_pendingSave) {
      return;
    }

    _isSaving = true;
    _pendingSave = false;
    _state = AutosaveState.saving;
    notifyListeners();

    try {
      await onSave();
      _lastSaveTime = DateTime.now();
      _state = AutosaveState.saved;
    } catch (e) {
      _state = AutosaveState.error;
      debugPrint('Autosave error: $e');
    } finally {
      _isSaving = false;
      notifyListeners();

      // Check if there's a pending save
      if (_pendingSave) {
        _pendingSave = false;
        _state = AutosaveState.dirty;
        markDirty();
      }
    }
  }

  /// Cancel any pending saves
  void cancel() {
    _debounceTimer?.cancel();
    _pendingSave = false;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Get display text for current state
  String get stateText {
    switch (_state) {
      case AutosaveState.saved:
        return 'Kaydedildi';
      case AutosaveState.dirty:
        return 'Değişiklikler var';
      case AutosaveState.saving:
        return 'Kaydediliyor...';
      case AutosaveState.error:
        return 'Kaydetme hatası';
    }
  }
}

/// Autosave state enum
enum AutosaveState { saved, dirty, saving, error }
