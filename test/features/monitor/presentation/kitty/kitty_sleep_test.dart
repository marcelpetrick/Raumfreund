// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/theme/app_colors.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_character.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_painter.dart';
import 'package:raumfreund/features/monitor/presentation/kitty/kitty_pose.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';

import '../../../../shared/widgets/test_app.dart';

/// Sleeping Mia and her wake-up (ADR 0005).
void main() {
  _poseTests();
  _painterTests();
  _characterTests();
}

void _poseTests() {
  group('sleeping pose', () {
    test('eyes closed, relaxed ears, breathing, no trembling', () {
      final top = KittyPose.of(KittyMood.sleeping, 0.25, 0);
      final bottom = KittyPose.of(KittyMood.sleeping, 0.75, 0);
      expect(top.eyeOpen, 0);
      expect(top.earDroop, closeTo(0.3, 1e-9));
      expect(top.bobDy, closeTo(1.4, 1e-9));
      expect(bottom.bobDy, closeTo(-1.4, 1e-9));
      expect(top.shakeDx, 0);
      expect(top.walking, isFalse);
      expect(top.wake, isNull);
    });

    test('mood colour and German description', () {
      expect(KittyMood.sleeping.glowColor, AppColors.lavender);
      expect(KittyMood.sleeping.describe(l10nDe), l10nDe.kittySleeping);
    });
  });

  group('waking pose', () {
    KittyPose at(double wake, [KittyMood mood = KittyMood.happy]) =>
        KittyPose.of(mood, 0.5, 0, wake: wake);

    test('yawns first with closed eyes', () {
      expect(at(0.2).yawn, greaterThan(0.8));
      expect(at(0.2).eyeOpen, 0);
      expect(at(0.5).yawn, closeTo(0, 1e-9));
    });

    test('opens the eyes, blinks once and is wide awake at the end', () {
      expect(at(0.5).eyeOpen, inExclusiveRange(0.2, 0.6));
      expect(at(0.62).eyeOpen, lessThan(at(0.55).eyeOpen));
      expect(at(0.95).eyeOpen, closeTo(1, 1e-9));
    });

    test('stretches up with lifted paws and perks up the ears', () {
      final stretch = at(0.525);
      expect(stretch.bobDy, closeTo(-7, 1e-9));
      expect(stretch.leftPawLift, closeTo(5, 1e-9));
      expect(stretch.rightPawLift, closeTo(5, 1e-9));
      expect(at(0).earDroop, closeTo(0.3, 1e-9));
      expect(at(1).earDroop, 0);
      expect(at(1, KittyMood.uneasy).earDroop, closeTo(0.75, 1e-9));
      expect(at(1).bobDy, closeTo(0, 1e-9));
    });

    test('keeps the progress, clamped, and ignores it while asleep', () {
      expect(at(1.5).wake, 1);
      expect(at(-1).wake, 0);
      expect(KittyPose.of(KittyMood.sleeping, 0, 0, wake: 0.5).wake, isNull);
    });
  });
}

void _painterTests() {
  group('KittyPainter while sleeping and waking', () {
    test('paints every wake-up frame into every mood with items', () {
      for (final mood in KittyMood.values) {
        for (var wake = 0.0; wake <= 1; wake += 0.05) {
          final recorder = ui.PictureRecorder();
          KittyPainter(
            mood: mood,
            phase: wake,
            walk: 0,
            wake: wake,
            accessories: KittyAccessory.values.toSet(),
          ).paint(Canvas(recorder), const Size(240, 224));
          recorder.endRecording().dispose();
        }
      }
    });

    test('repaints when the wake-up progress changes', () {
      final a = KittyPainter(mood: rt(KittyMood.idle), phase: 0, walk: 0);
      expect(
        a.shouldRepaint(
          const KittyPainter(mood: KittyMood.idle, phase: 0, walk: 0, wake: 0),
        ),
        isTrue,
      );
    });
  });
}

Future<void> _pump(
  WidgetTester tester,
  KittyMood mood, {
  bool reduceMotion = false,
  bool walkedAway = false,
  bool wakeUp = true,
}) => tester.pumpWidget(
  testApp(
    Center(
      child: SizedBox(
        width: 240,
        height: 224,
        child: KittyCharacter(
          mood: mood,
          reduceMotion: reduceMotion,
          walkedAway: walkedAway,
          wakeUp: wakeUp,
        ),
      ),
    ),
    scaffold: false,
  ),
);

/// Wake-up progress of the painters on screen (null: nobody wakes up).
Iterable<double?> _wakes(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.descendant(
        of: find.byType(KittyCharacter),
        matching: find.byType(CustomPaint),
      ),
    )
    .map((paint) => paint.painter)
    .whereType<KittyPainter>()
    .map((painter) => painter.wake);

void _characterTests() {
  group('KittyCharacter waking up', () {
    testWidgets('wakes up when sleep ends, then shows the mood', (
      tester,
    ) async {
      await _pump(tester, KittyMood.sleeping);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.bySemanticsLabel(l10nDe.kittySleeping), findsOneWidget);
      expect(_wakes(tester), everyElement(isNull));
      await _pump(tester, KittyMood.happy);
      await tester.pump(const Duration(milliseconds: 800));
      expect(_wakes(tester), contains(isNotNull));
      await tester.pump(KittyCharacter.wakeDuration);
      expect(_wakes(tester), everyElement(isNull));
      expect(find.bySemanticsLabel(l10nDe.kittyHappy), findsOneWidget);
    });

    testWidgets('starts asleep, then yawns and stretches', (tester) async {
      await _pump(tester, KittyMood.sleeping);
      await _pump(tester, KittyMood.happy);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_wakes(tester), contains(lessThan(kKittyWakeLead)));
      await tester.pump(const Duration(milliseconds: 900));
      expect(_wakes(tester), contains(greaterThan(kKittyWakeLead)));
    });

    testWidgets('a failed or stopped wake-up only crossfades', (tester) async {
      await _pump(tester, KittyMood.sleeping);
      await _pump(tester, KittyMood.idle, wakeUp: false);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_wakes(tester), everyElement(isNull));
    });

    testWidgets('running away during the wake-up ends it', (tester) async {
      await _pump(tester, KittyMood.sleeping);
      await _pump(tester, KittyMood.scared);
      await tester.pump(const Duration(milliseconds: 400));
      await _pump(tester, KittyMood.scared, walkedAway: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_wakes(tester), everyElement(isNull));
    });

    testWidgets('falling asleep again stops waking up', (tester) async {
      await _pump(tester, KittyMood.sleeping);
      await _pump(tester, KittyMood.idle);
      await tester.pump(const Duration(milliseconds: 400));
      await _pump(tester, KittyMood.sleeping);
      await tester.pump(KittyCharacter.fadeDuration);
      expect(_wakes(tester), everyElement(isNull));
    });

    testWidgets('no wake-up between awake moods', (tester) async {
      await _pump(tester, KittyMood.idle);
      await _pump(tester, KittyMood.happy);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_wakes(tester), everyElement(isNull));
    });

    testWidgets('reduced motion only crossfades', (tester) async {
      await _pump(tester, KittyMood.sleeping, reduceMotion: true);
      await _pump(tester, KittyMood.happy, reduceMotion: true);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_wakes(tester), everyElement(isNull));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
