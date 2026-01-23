import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

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
    return path;
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<void> dispose() async {
    _recorder.dispose();
  }

  Future<void> pause() async {
    await _recorder.pause();
  }

  Future<void> resume() async {
    await _recorder.resume();
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<bool> isPaused() async {
    return await _recorder.isPaused();
  }
}
