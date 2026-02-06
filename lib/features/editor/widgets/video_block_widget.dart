import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoBlockWidget extends StatefulWidget {
  final String path;
  final bool isReadOnly;

  const VideoBlockWidget({
    super.key,
    required this.path,
    this.isReadOnly = false,
  });

  @override
  State<VideoBlockWidget> createState() => _VideoBlockWidgetState();
}

class _VideoBlockWidgetState extends State<VideoBlockWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    final file = File(widget.path);
    if (!file.existsSync()) return;

    final controller = VideoPlayerController.file(file);
    _controller = controller;
    try {
      await controller.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_isInitialized || controller == null) {
      return Container(
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        if (!widget.isReadOnly)
          GestureDetector(
            onTap: () {
              setState(() {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent, // Hit test for the whole area
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
