import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/models/block.dart';

void main() {
  test('block payload is cached and copyWith updates values', () {
    final block = Block(
      id: 'b1',
      pageId: 'p1',
      type: BlockType.text,
      x: 0.1,
      y: 0.2,
      width: 0.3,
      height: 0.4,
      payloadJson: '{"content":"hello"}',
    );

    final firstPayload = block.payload;
    final secondPayload = block.payload;

    expect(identical(firstPayload, secondPayload), isTrue);

    final updated = block.copyWith(x: 0.5, payloadJson: '{"content":"new"}');
    expect(updated.x, equals(0.5));
    expect(updated.payload['content'], equals('new'));
  });

  test('text payload round-trip works', () {
    final payload = TextBlockPayload(
      content: 'abc',
      fontSize: 18,
      color: '#ffffff',
      fontFamily: 'serif',
      textAlign: 'center',
    );

    final decoded = TextBlockPayload.fromJson(payload.toJson());

    expect(decoded.content, equals('abc'));
    expect(decoded.fontSize, equals(18));
    expect(decoded.color, equals('#ffffff'));
    expect(decoded.fontFamily, equals('serif'));
    expect(decoded.textAlign, equals('center'));
  });

  test('image payload round-trip works', () {
    final payload = ImageBlockPayload(
      assetId: 'a1',
      path: '/tmp/p.png',
      originalWidth: 100,
      originalHeight: 200,
      caption: 'cap',
      frameStyle: ImageFrameStyles.gradient,
      storagePath: 'images/a1.png',
    );

    final decoded = ImageBlockPayload.fromJson(payload.toJson());

    expect(decoded.assetId, equals('a1'));
    expect(decoded.path, equals('/tmp/p.png'));
    expect(decoded.originalWidth, equals(100));
    expect(decoded.originalHeight, equals(200));
    expect(decoded.caption, equals('cap'));
    expect(decoded.frameStyle, equals(ImageFrameStyles.gradient));
    expect(decoded.storagePath, equals('images/a1.png'));
  });

  test('audio and video payload defaults and fields are parsed', () {
    final audio = AudioBlockPayload.fromJson({
      'path': '/tmp/audio.m4a',
      'durationMs': 1500,
      'storagePath': 'audio/a.m4a',
    });

    final video = VideoBlockPayload.fromJson({
      'path': '/tmp/video.mp4',
      'durationMs': 2000,
      'caption': 'clip',
    });

    expect(audio.path, equals('/tmp/audio.m4a'));
    expect(audio.durationMs, equals(1500));
    expect(audio.storagePath, equals('audio/a.m4a'));

    expect(video.path, equals('/tmp/video.mp4'));
    expect(video.durationMs, equals(2000));
    expect(video.caption, equals('clip'));
  });

  test('all frame styles include expected style ids', () {
    expect(ImageFrameStyles.all, contains(ImageFrameStyles.none));
    expect(ImageFrameStyles.all, contains(ImageFrameStyles.gradient));
    expect(ImageFrameStyles.all, contains(ImageFrameStyles.polaroidClassic));
    expect(ImageFrameStyles.all.length, equals(16));
  });
}
