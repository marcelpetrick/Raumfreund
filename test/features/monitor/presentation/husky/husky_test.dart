// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/presentation/husky/husky_character.dart';
import 'package:raumfreund/features/monitor/presentation/husky/husky_painter.dart';
import 'package:raumfreund/features/monitor/presentation/husky/husky_shapes.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_character.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_pose.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';

import '../../../../shared/widgets/test_app.dart';

Future<Uint8List> _pixels(HuskyPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(size.width.toInt(), size.height.toInt());
  final data = (await image.toByteData())!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return data;
}

Widget _husky({
  KittyMood mood = KittyMood.idle,
  bool away = false,
  bool reduced = false,
  bool wake = false,
  double? danceProgress,
  Set<KittyAccessory> accessories = const {},
}) => testApp(
  Center(
    child: SizedBox(
      width: 320,
      height: 230,
      child: HuskyCharacter(
        mood: mood,
        semanticLabel: 'Flocke wartet',
        awayLabel: 'Flocke versteckt sich',
        walkedAway: away,
        reduceMotion: reduced,
        wakeUp: wake,
        danceProgress: danceProgress,
        accessories: accessories,
      ),
    ),
  ),
  scaffold: false,
);

HuskyPainter _visiblePainter(WidgetTester tester) => tester
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((paint) => paint.painter)
    .whereType<HuskyPainter>()
    .last;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  _eyeTests();
  _danceTests();
  _paintingTests();
  _boundsTests();
  _characterTests();
}

void _eyeTests() {
  test('eyes look back while running and ahead when returning', () async {
    Future<Uint8List> face(bool running) async {
      final recorder = ui.PictureRecorder();
      paintHuskyFace(
        Canvas(recorder),
        KittyMood.idle,
        KittyPose.of(KittyMood.idle, 0, 0.5, running: running),
      );
      final picture = recorder.endRecording();
      final image = await picture.toImage(240, 224);
      final bytes = (await image.toByteData())!.buffer.asUint8List();
      image.dispose();
      picture.dispose();
      return bytes;
    }

    final running = await face(true);
    final returning = await face(false);
    expect(running, isNot(equals(returning)));
  });

  test('both eyes have matching blue irises', () async {
    const size = Size(320, 304);
    final pixels = await _pixels(
      const HuskyPainter(mood: KittyMood.idle, phase: 0, walk: 0),
      size,
    );
    List<int> pixel(int x, int y) {
      final offset = (y * size.width.toInt() + x) * 4;
      return pixels.sublist(offset, offset + 4);
    }

    final blue = pixel(128, 136);
    final right = pixel(192, 136);
    expect(blue[2], greaterThan(blue[1]));
    expect(right[2], greaterThan(right[1]));
    expect(right, blue);
  });
}

void _danceTests() {
  test('dance moves the dog and returns exactly to its rest frame', () async {
    const size = Size(320, 304);
    Future<Uint8List> frame(double? progress) => _pixels(
      HuskyPainter(
        mood: KittyMood.idle,
        phase: 0,
        walk: 0,
        danceProgress: progress,
      ),
      size,
    );
    final rest = await frame(null);
    expect(await frame(0), rest);
    expect(await frame(1), rest);
    expect(await frame(0.18), isNot(equals(rest)));
  });

  test('dance leaves the stage and toy on the floor', () async {
    const size = Size(320, 304);
    Future<Uint8List> frame(double progress) => _pixels(
      HuskyPainter(
        mood: KittyMood.idle,
        phase: 0,
        walk: 0,
        accessories: const {KittyAccessory.mouse},
        danceProgress: progress,
      ),
      size,
    );
    final rest = await frame(0);
    final dancing = await frame(0.18);
    for (var y = 225; y < 264; y++) {
      for (var x = 20; x < 90; x++) {
        final offset = (y * size.width.toInt() + x) * 4;
        for (var channel = 0; channel < 4; channel++) {
          // A faint moving silhouette halo may overlap the stationary stage.
          expect(
            (dancing[offset + channel] - rest[offset + channel]).abs(),
            lessThan(12),
            reason: 'stage/toy pixel at $x,$y',
          );
        }
      }
    }
  });

  test('sleeping, walking away and waking suppress the dance', () async {
    const size = Size(320, 304);
    for (final (mood, walk, wake) in [
      (KittyMood.sleeping, 0.0, null),
      (KittyMood.idle, 0.5, null),
      (KittyMood.idle, 0.0, 0.7),
    ]) {
      final base = HuskyPainter(mood: mood, phase: 0, walk: walk, wake: wake);
      final dance = HuskyPainter(
        mood: mood,
        phase: 0,
        walk: walk,
        wake: wake,
        danceProgress: 0.18,
      );
      expect(await _pixels(dance, size), await _pixels(base, size));
    }
  });
}

void _paintingTests() {
  test('each owned accessory visibly changes the painter', () async {
    const size = Size(320, 304);
    final base = await _pixels(
      const HuskyPainter(mood: KittyMood.idle, phase: 0, walk: 0),
      size,
    );
    for (final item in KittyAccessory.values) {
      final withItem = await _pixels(
        HuskyPainter(
          mood: KittyMood.idle,
          phase: 0,
          walk: 0,
          accessories: {item},
        ),
        size,
      );
      final different = List.generate(
        base.length,
        (i) => base[i] != withItem[i],
      );
      expect(
        different.where((value) => value).length,
        greaterThan(80),
        reason: item.name,
      );
    }
  });

  test('moods and accessories fade before the clipped edges', () async {
    for (final size in [const Size(240, 230), const Size(500, 250)]) {
      for (final mood in KittyMood.values) {
        for (final phase in [0.0, 0.5, 0.95]) {
          final pixels = await _pixels(
            HuskyPainter(
              mood: mood,
              phase: phase,
              walk: 0,
              accessories: KittyAccessory.values.toSet(),
            ),
            size,
          );
          final width = size.width.toInt();
          final height = size.height.toInt();
          final edges = <int>[
            for (var x = 0; x < width; x++) ...[
              pixels[x * 4 + 3],
              pixels[((height - 1) * width + x) * 4 + 3],
            ],
            for (var y = 0; y < height; y++) ...[
              pixels[y * width * 4 + 3],
              pixels[(y * width + width - 1) * 4 + 3],
            ],
          ];
          expect(
            edges.reduce((a, b) => a > b ? a : b),
            lessThan(12),
            reason: '$size $mood $phase',
          );
        }
      }
    }
  });
}

void _boundsTests() {
  test('dance and all accessories stay inside the scene', () async {
    for (final size in [const Size(240, 230), const Size(500, 250)]) {
      for (final progress in [0.1, 0.18, 0.4, 0.7, 0.9]) {
        final pixels = await _pixels(
          HuskyPainter(
            mood: KittyMood.idle,
            phase: 0,
            walk: 0,
            accessories: KittyAccessory.values.toSet(),
            danceProgress: progress,
          ),
          size,
        );
        final width = size.width.toInt();
        final height = size.height.toInt();
        final topAndBottom = [
          for (var x = 0; x < width; x++) ...[
            pixels[x * 4 + 3],
            pixels[((height - 1) * width + x) * 4 + 3],
          ],
        ];
        final sides = [
          for (var y = 0; y < height; y++) ...[
            pixels[(y * width) * 4 + 3],
            pixels[(y * width + width - 1) * 4 + 3],
          ],
        ];
        expect(
          [...topAndBottom, ...sides].reduce((a, b) => a > b ? a : b),
          lessThan(12),
          reason: '$size at dance progress $progress',
        );
      }
    }
  });

  test('repaint and walk displacement follow the frame inputs', () {
    const initial = HuskyPainter(mood: KittyMood.idle, phase: 0, walk: 0);
    expect(initial.shouldRepaint(initial), isFalse);
    expect(
      initial.shouldRepaint(
        const HuskyPainter(mood: KittyMood.happy, phase: 0, walk: 0),
      ),
      isTrue,
    );
    expect(HuskyPainter.walkOffset(Size.zero, 1), 0);
    expect(HuskyPainter.walkOffset(const Size(240, 230), 1), greaterThan(240));
    expect(
      initial.shouldRepaint(
        const HuskyPainter(
          mood: KittyMood.idle,
          phase: 0,
          walk: 0,
          danceProgress: 0.5,
        ),
      ),
      isTrue,
    );
  });
}

void _characterTests() {
  testWidgets('reduced motion and away state suppress the shop dance', (
    tester,
  ) async {
    await tester.pumpWidget(_husky(danceProgress: 0.18));
    expect(_visiblePainter(tester).danceProgress, 0.18);
    await tester.pumpWidget(_husky(danceProgress: 0.18, reduced: true));
    await tester.pump(KittyCharacter.fadeDuration);
    expect(_visiblePainter(tester).danceProgress, isNull);
    await tester.pumpWidget(_husky(danceProgress: 0.18, away: true));
    await tester.pump(KittyCharacter.fadeDuration);
    expect(_visiblePainter(tester).danceProgress, isNull);
  });

  testWidgets('initially away is immediately hidden, including on remount', (
    tester,
  ) async {
    await tester.pumpWidget(_husky(away: true));
    expect(_visiblePainter(tester).walk, 1);
    expect(find.text('Flocke versteckt sich'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_husky(away: true));
    expect(_visiblePainter(tester).walk, 1);
  });

  testWidgets('runs away and walks back with Mia timing', (tester) async {
    await tester.pumpWidget(_husky());
    await tester.pumpWidget(_husky(mood: KittyMood.scared, away: true));
    await tester.pump(KittyCharacter.runDuration);
    expect(_visiblePainter(tester).walk, 1);
    expect(find.text('Flocke versteckt sich'), findsOneWidget);
    await tester.pumpWidget(_husky(mood: KittyMood.happy));
    await tester.pump(KittyCharacter.walkDuration);
    await tester.pump(KittyCharacter.fadeDuration);
    expect(_visiblePainter(tester).walk, 0);
  });

  testWidgets('sleep wakes on successful return and reduced motion stops it', (
    tester,
  ) async {
    await tester.pumpWidget(_husky(mood: KittyMood.sleeping));
    await tester.pumpWidget(_husky(mood: KittyMood.happy, wake: true));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_visiblePainter(tester).wake, isNotNull);
    await tester.pumpWidget(_husky(mood: KittyMood.happy, reduced: true));
    await tester.pump(
      KittyCharacter.fadeDuration + const Duration(milliseconds: 50),
    );
    expect(_visiblePainter(tester).wake, isNull);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('semantics include the visible equipped items', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _husky(reduced: true, accessories: {KittyAccessory.scarf}),
    );
    expect(
      find.bySemanticsLabel('Flocke wartet. Bei Flocke: Schal'),
      findsOneWidget,
    );
    await tester.pumpWidget(
      _husky(away: true, reduced: true, accessories: {KittyAccessory.scarf}),
    );
    await tester.pump(KittyCharacter.fadeDuration);
    expect(find.bySemanticsLabel('Flocke versteckt sich'), findsOneWidget);
    await tester.pumpWidget(
      _husky(
        away: true,
        reduced: true,
        accessories: {KittyAccessory.scarf, KittyAccessory.mouse},
      ),
    );
    expect(
      find.bySemanticsLabel('Flocke versteckt sich. Spielzeugmaus'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
