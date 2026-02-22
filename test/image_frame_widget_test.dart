import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_app/core/models/block.dart';
import 'package:journal_app/features/editor/widgets/image_frame_widget.dart';

const List<int> _kTransparentImage = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

void main() {
  final imageProvider = MemoryImage(Uint8List.fromList(_kTransparentImage));

  testWidgets('renders all known frame styles without crashing', (
    tester,
  ) async {
    for (final frameStyle in ImageFrameStyles.all) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ImageFrameWidget(
                imageProvider: imageProvider,
                frameStyle: frameStyle,
                width: 120,
                height: 80,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(Image), findsOneWidget, reason: frameStyle);
      expect(tester.takeException(), isNull, reason: frameStyle);
    }
  });

  testWidgets('uses ResizeImage when cache dimensions are provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImageFrameWidget(
            imageProvider: imageProvider,
            frameStyle: ImageFrameStyles.none,
            width: 100,
            height: 100,
            cacheWidth: 64,
            cacheHeight: 64,
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<ResizeImage>());
  });

  testWidgets('falls back to default clip for unknown style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ImageFrameWidget(
            imageProvider: imageProvider,
            frameStyle: 'unknown-style',
            width: 80,
            height: 80,
          ),
        ),
      ),
    );

    expect(find.byType(ClipRRect), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
