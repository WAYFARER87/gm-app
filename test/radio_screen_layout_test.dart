import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal widget replicating the radio artwork sizing logic.
class _TestRadioArtwork extends StatelessWidget {
  const _TestRadioArtwork();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.8;
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: const Placeholder(),
          ),
        );
      },
    );
  }
}

void main() {
  testWidgets('Artwork fits on small portrait screens', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(320, 480);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(const MaterialApp(home: _TestRadioArtwork()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Artwork fits on small landscape screens', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(480, 320);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(const MaterialApp(home: _TestRadioArtwork()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
