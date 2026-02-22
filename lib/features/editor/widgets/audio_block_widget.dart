import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Widget to display and play an audio block with waveform visualization
class AudioBlockWidget extends StatefulWidget {
  final String path;
  final int? durationMs;

  const AudioBlockWidget({super.key, required this.path, this.durationMs});

  @override
  State<AudioBlockWidget> createState() => _AudioBlockWidgetState();
}

class _AudioBlockWidgetState extends State<AudioBlockWidget> {
  final AudioPlayer _player = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  // Simulated waveform bars (in real app, extract from audio file)
  late final List<double> _waveformBars;

  @override
  void initState() {
    super.initState();

    // Generate deterministic waveform from path hash
    final rng = Random(widget.path.hashCode);
    _waveformBars = List.generate(40, (_) => rng.nextDouble() * 0.7 + 0.3);

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    if (widget.durationMs != null) {
      _duration = Duration(milliseconds: widget.durationMs!);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playerState == PlayerState.playing) {
      await _player.pause();
    } else {
      await _player.play(DeviceFileSource(widget.path));
    }
  }

  Future<void> _seekTo(double ratio) async {
    if (_duration.inMilliseconds > 0) {
      final pos = Duration(
        milliseconds: (ratio * _duration.inMilliseconds).round(),
      );
      await _player.seek(pos);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = _playerState == PlayerState.playing;
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _duration.inMilliseconds > 0
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Play/Pause Button
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: colorScheme.onPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Waveform + Time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Waveform bars
                GestureDetector(
                  onTapDown: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final localX = details.localPosition.dx;
                    // Approximate: waveform starts ~62px from left
                    final waveWidth = box.size.width - 62;
                    if (waveWidth > 0) {
                      _seekTo((localX / waveWidth).clamp(0.0, 1.0));
                    }
                  },
                  child: SizedBox(
                    height: 32,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        bars: _waveformBars,
                        progress: progress,
                        activeColor: colorScheme.primary,
                        inactiveColor: colorScheme.primary.withValues(
                          alpha: 0.25,
                        ),
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Duration text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for waveform visualization
class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final barWidth = size.width / (bars.length * 2 - 1);
    final maxHeight = size.height;

    for (int i = 0; i < bars.length; i++) {
      final x = i * barWidth * 2;
      final barHeight = bars[i] * maxHeight;
      final y = (maxHeight - barHeight) / 2;

      final isActive = (i / bars.length) <= progress;
      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
