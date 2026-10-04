// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/theme/app_colors.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_character.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_painter.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_pose.dart';

import '../../../../shared/widgets/test_app.dart';

Widget _kitty({
  required KittyMood mood,
  bool walkedAway = false,
  bool reduceMotion = false,
}) => Center(
  child: SizedBox(
    width: 240,
    height: 224,
    child: KittyCharacter(
      mood: rt(mood),
      walkedAway: rt(walkedAway),
      reduceMotion: rt(reduceMotion),
    ),
  ),
);

Future<void> _pump(
  WidgetTester tester, {
  required KittyMood mood,
  bool walkedAway = false,
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    testApp(
      _kitty(mood: mood, walkedAway: walkedAway, reduceMotion: reduceMotion),
      scaffold: false,
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  _poseTests();
  _painterTests();
  _characterTests();
}

void _poseTests() {
  group('KittyPose', () {
    test('idle blinks only at the end of the loop', () {
      expect(KittyPose.of(KittyMood.idle, 0, 0).eyeOpen, 1);
      expect(KittyPose.of(KittyMood.idle, 0.96, 0).eyeOpen, lessThan(0.2));
      expect(KittyPose.of(KittyMood.happy, 0.96, 0).eyeOpen, 1);
    });

    test('ears droop with discomfort', () {
      expect(KittyPose.of(KittyMood.happy, 0, 0).earDroop, 0);
      expect(KittyPose.of(KittyMood.uneasy, 0, 0).earDroop, 0.75);
      expect(KittyPose.of(KittyMood.crying, 0, 0).earDroop, 1);
    });

    test('happy tail sways, crying sobs', () {
      expect(
        KittyPose.of(KittyMood.happy, 0.125, 0).tailAngle,
        closeTo(0.22, 1e-9),
      );
      expect(
        KittyPose.of(KittyMood.crying, 1 / 32, 0).shakeDx,
        closeTo(1.8, 1e-9),
      );
      expect(KittyPose.of(KittyMood.uneasy, 0, 0).lookDx, -3);
    });

    test('walk cycle lifts paws alternately and only while walking', () {
      const step = 1 / (kKittyWalkSteps * 4);
      final a = KittyPose.of(KittyMood.crying, 0, step);
      final b = KittyPose.of(KittyMood.crying, 0, step * 3);
      expect(a.walking, isTrue);
      expect(a.leftPawLift, closeTo(8, 1e-9));
      expect(a.rightPawLift, 0);
      expect(b.rightPawLift, closeTo(8, 1e-9));
      expect(a.shakeDx, 0);
      expect(KittyPose.of(KittyMood.crying, 0, 1).walking, isFalse);
      expect(KittyPose.of(KittyMood.crying, 0, 0).leftPawLift, 0);
    });
  });

  test('KittyMood maps to glow colours and German descriptions', () {
    expect(KittyMood.happy.glowColor, AppColors.green);
    expect(KittyMood.uneasy.glowColor, AppColors.yellow);
    expect(KittyMood.crying.glowColor, AppColors.red);
    expect(KittyMood.idle.glowColor, AppColors.lavender);
    expect(KittyMood.happy.describe(l10nDe), 'Mia ist fröhlich und schnurrt');
    expect(KittyMood.idle.describe(l10nDe), l10nDe.kittyIdle);
    expect(KittyMood.uneasy.describe(l10nDe), l10nDe.kittyUneasy);
    expect(KittyMood.crying.describe(l10nDe), l10nDe.kittyCrying);
  });
}

void _painterTests() {
  group('KittyPainter', () {
    test('paints every mood and walk state without errors', () {
      for (final mood in KittyMood.values) {
        for (final walk in [0.0, 0.3, 1.0]) {
          final recorder = ui.PictureRecorder();
          KittyPainter(
            mood: mood,
            phase: 0.95,
            walk: walk,
          ).paint(Canvas(recorder), const Size(240, 224));
          recorder.endRecording().dispose();
        }
      }
      final recorder = ui.PictureRecorder();
      KittyPainter(
        mood: rt(KittyMood.idle),
        phase: 0,
        walk: 0,
      ).paint(Canvas(recorder), Size.zero);
      recorder.endRecording().dispose();
    });

    test('repaints only when a parameter changes', () {
      final a = KittyPainter(mood: rt(KittyMood.happy), phase: 0, walk: 0);
      expect(
        a.shouldRepaint(
          const KittyPainter(mood: KittyMood.happy, phase: 0, walk: 0),
        ),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          const KittyPainter(mood: KittyMood.idle, phase: 0, walk: 0),
        ),
        isTrue,
      );
      expect(
        a.shouldRepaint(
          const KittyPainter(mood: KittyMood.happy, phase: .1, walk: 0),
        ),
        isTrue,
      );
      expect(
        a.shouldRepaint(
          const KittyPainter(mood: KittyMood.happy, phase: 0, walk: 1),
        ),
        isTrue,
      );
    });

    test('walk offset moves Mia completely off the canvas', () {
      const size = Size(240, 224);
      expect(KittyPainter.walkOffset(size, 0), 0);
      expect(KittyPainter.walkOffset(size, 1), greaterThan(240));
    });
  });
}

void _characterTests() {
  group('KittyCharacter', () {
    for (final mood in KittyMood.values) {
      testWidgets('announces the ${mood.name} mood', (tester) async {
        await _pump(tester, mood: mood);
        expect(find.bySemanticsLabel(mood.describe(l10nDe)), findsOneWidget);
      });
    }

    testWidgets('semantics are an image with the mood label', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, mood: KittyMood.happy, reduceMotion: true);
      expect(
        tester.getSemantics(find.byType(KittyCharacter)),
        matchesSemantics(label: 'Mia ist fröhlich und schnurrt', isImage: true),
      );
      handle.dispose();
    });

    testWidgets('walks away, shows the sign and walks back', (tester) async {
      await _pump(tester, mood: KittyMood.crying);
      expect(find.byType(AwaySign), findsNothing);
      await _pump(tester, mood: KittyMood.crying, walkedAway: true);
      await tester.pump(KittyCharacter.walkDuration);
      expect(find.text(l10nDe.kittyAwaySign), findsOneWidget);
      expect(find.bySemanticsLabel(l10nDe.kittyAwaySign), findsOneWidget);
      await _pump(tester, mood: KittyMood.happy);
      await tester.pump(KittyCharacter.walkDuration);
      await tester.pump(KittyCharacter.fadeDuration);
      expect(find.byType(AwaySign), findsNothing);
      expect(find.bySemanticsLabel(l10nDe.kittyHappy), findsOneWidget);
    });

    testWidgets('reduced motion only crossfades and stops the loop', (
      tester,
    ) async {
      await _pump(tester, mood: KittyMood.happy, reduceMotion: true);
      expect(tester.hasRunningAnimations, isFalse);
      await _pump(
        tester,
        mood: KittyMood.crying,
        walkedAway: true,
        reduceMotion: true,
      );
      await tester.pump(KittyCharacter.fadeDuration);
      expect(find.byType(AwaySign), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      await _pump(tester, mood: KittyMood.crying, walkedAway: true);
      expect(tester.hasRunningAnimations, isTrue);
      await _pump(tester, mood: KittyMood.idle, reduceMotion: true);
      await tester.pump(KittyCharacter.fadeDuration);
      expect(find.byType(AwaySign), findsNothing);
    });
  });
}
