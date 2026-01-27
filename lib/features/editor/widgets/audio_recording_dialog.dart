import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:journal_app/features/editor/services/audio_recorder_service.dart';

class AudioRecordingDialog extends StatefulWidget {
  final AudioRecorderService recorder;

  const AudioRecordingDialog({super.key, required this.recorder});

  @override
  State<AudioRecordingDialog> createState() => _AudioRecordingDialogState();
}

class _AudioRecordingDialogState extends State<AudioRecordingDialog>
    with SingleTickerProviderStateMixin {
  bool _isPaused = false;
  late List<double> _waveformHeights;
  Timer? _waveformTimer;

  @override
  void initState() {
    super.initState();
    // Initialize random waveform heights
    _waveformHeights = List.generate(
      25,
      (_) => Random().nextDouble() * 60 + 20,
    );
    _startWaveformAnimation();
  }

  void _startWaveformAnimation() {
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_isPaused) {
        setState(() {
          _waveformHeights = List.generate(
            25,
            (_) => Random().nextDouble() * 60 + 20,
          );
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ses Kaydediliyor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer
          StreamBuilder<Duration>(
            stream: widget.recorder.durationStream,
            builder: (context, snapshot) {
              final duration = snapshot.data ?? widget.recorder.currentDuration;
              return Text(
                _formatDuration(duration),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Waveform
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _waveformHeights.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4,
                  height: entry.value,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: _isPaused ? 0.3 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pause/Resume
              IconButton.filledTonal(
                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                iconSize: 32,
                onPressed: () async {
                  if (_isPaused) {
                    await widget.recorder.resume();
                    setState(() => _isPaused = false);
                  } else {
                    await widget.recorder.pause();
                    setState(() => _isPaused = true);
                  }
                },
              ),
              const SizedBox(width: 16),
              // Stop/Save
              IconButton.filled(
                icon: const Icon(Icons.stop),
                iconSize: 32,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final path = await widget.recorder.stopRecording();
                  if (context.mounted) Navigator.pop(context, path);
                },
              ),
              const SizedBox(width: 16),
              // Cancel
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 32,
                onPressed: () {
                  widget.recorder.stopRecording();
                  if (mounted) Navigator.pop(context, null);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    super.dispose();
  }
}
