// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_mood.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_painter.dart';
import 'package:raumfreund/features/monitor/presentation/level_gauge.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';

Future<List<int>> _edgeAlphas(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final bytes = (await image.toByteData())!;
  final pixels = bytes.buffer.asUint8List();
  final width = image.width;
  final height = image.height;
  final alphas = <int>[];
  for (var x = 0; x < width; x++) {
    alphas.add(pixels[(x * 4) + 3]);
    alphas.add(pixels[((height - 1) * width + x) * 4 + 3]);
  }
  for (var y = 0; y < height; y++) {
    alphas.add(pixels[(y * width) * 4 + 3]);
    alphas.add(pixels[(y * width + width - 1) * 4 + 3]);
  }
  image.dispose();
  picture.dispose();
  return alphas;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('gauge track and glow fade before the canvas edge', () async {
    for (final width in [240.0, 360.0, 600.0]) {
      final alphas = await _edgeAlphas(
        LevelGaugePainter(
          levelDb: 100,
          thresholds: Thresholds.defaults,
          color: Colors.red,
        ),
        Size(width, 210),
      );
      expect(alphas.reduce((a, b) => a > b ? a : b), lessThan(8));
    }
  });

  test('Mia and accessories fade before the stage edge', () async {
    for (final size in [const Size(240, 230), const Size(500, 250)]) {
      for (final mood in KittyMood.values) {
        for (final phase in [0.0, 0.5, 0.95]) {
          final alphas = await _edgeAlphas(
            KittyPainter(
              mood: mood,
              phase: phase,
              walk: 0,
              accessories: KittyAccessory.values.toSet(),
            ),
            size,
          );
          expect(
            alphas.reduce((a, b) => a > b ? a : b),
            lessThan(12),
            reason: '$size $mood at $phase',
          );
        }
      }
    }
  });
}
