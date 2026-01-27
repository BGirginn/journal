import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _durationTimer;
  Duration _currentDuration = Duration.zero;
  final _durationController = StreamController<Duration>.broadcast();
  DateTime? _recordingStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;

  Stream<Duration> get durationStream => _durationController.stream;
  Duration get currentDuration => _currentDuration;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<String> startRecording() async {
    if (!await hasPermission()) {
      throw Exception('Mikrofon izni yok');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'audio_${const Uuid().v4()}.m4a';
    final path = '${dir.path}/$fileName';

    await _recorder.start(const RecordConfig(), path: path);

    // Timer başlat
    _recordingStartTime = DateTime.now();
    _pausedDuration = Duration.zero;
    _currentDuration = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingStartTime != null) {
        _currentDuration =
            DateTime.now().difference(_recordingStartTime!) - _pausedDuration;
        _durationController.add(_currentDuration);
      }
    });

    return path;
  }

  Future<String?> stopRecording() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    _recordingStartTime = null;
    _pauseStartTime = null;
    // Keep final duration available until next start
    final path = await _recorder.stop();
    return path;
  }

  Future<void> dispose() async {
    _durationTimer?.cancel();
    _durationController.close();
    _recorder.dispose();
  }

  Future<void> pause() async {
    await _recorder.pause();
    _pauseStartTime = DateTime.now();
    _durationTimer?.cancel();
  }

  Future<void> resume() async {
    await _recorder.resume();
    if (_pauseStartTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseStartTime!);
      _pauseStartTime = null;
    }
    // Resume timer
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_recordingStartTime != null) {
        _currentDuration =
            DateTime.now().difference(_recordingStartTime!) - _pausedDuration;
        _durationController.add(_currentDuration);
      }
    });
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<bool> isPaused() async {
    return await _recorder.isPaused();
  }
}
