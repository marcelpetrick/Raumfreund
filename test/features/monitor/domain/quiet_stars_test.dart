// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/quiet_stars.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';

Duration ms(int value) => Duration(milliseconds: value);

/// Feeds [zone] every 100 ms in [fromMs, toMs]; returns how often a star
/// was earned.
int feed(
  QuietStars stars,
  Zone zone, {
  required int fromMs,
  required int toMs,
}) {
  var earned = 0;
  for (var t = fromMs; t <= toMs; t += 100) {
    stars.onSample(timestamp: ms(t), zone: zone);
    if (stars.earnedStarNow) earned++;
  }
  return earned;
}

void main() {
  late QuietStars stars;

  setUp(() => stars = QuietStars());

  test('starts without stars', () {
    expect(stars.stars, 0);
    expect(stars.progress, 0);
    expect(stars.earnedStarNow, isFalse);
    expect(stars.minute, const Duration(seconds: 60));
    expect(stars.maxGap, const Duration(seconds: 1));
  });

  test('earns a star after a full green minute, not before', () {
    expect(feed(stars, Zone.green, fromMs: 0, toMs: 59900), 0);
    expect(stars.progress, closeTo(59.9 / 60, 1e-9));
    stars.onSample(timestamp: ms(60000), zone: Zone.green);
    expect(stars.stars, 1);
    expect(stars.earnedStarNow, isTrue);
    expect(stars.progress, 0);
    stars.onSample(timestamp: ms(60100), zone: Zone.green);
    expect(stars.earnedStarNow, isFalse);
  });

  test('earns one star per minute of a long quiet run', () {
    expect(feed(stars, Zone.green, fromMs: 0, toMs: 180000), 3);
    expect(stars.stars, 3);
  });

  test('a non-green sample restarts the minute', () {
    feed(stars, Zone.green, fromMs: 0, toMs: 50000);
    stars.onSample(timestamp: ms(50100), zone: Zone.yellow);
    expect(stars.progress, 0);
    expect(feed(stars, Zone.green, fromMs: 50200, toMs: 110100), 0);
    expect(feed(stars, Zone.green, fromMs: 110200, toMs: 110200), 1);
  });

  test('a gap restarts the minute', () {
    feed(stars, Zone.green, fromMs: 0, toMs: 50000);
    stars.onSample(timestamp: ms(51001), zone: Zone.green);
    expect(stars.progress, 0);
    expect(feed(stars, Zone.green, fromMs: 51101, toMs: 110901), 0);
  });

  test('reset restarts the minute but keeps the stars', () {
    feed(stars, Zone.green, fromMs: 0, toMs: 60000);
    feed(stars, Zone.green, fromMs: 60100, toMs: 90000);
    stars.reset();
    expect(stars.stars, 1);
    expect(stars.progress, 0);
    stars.onSample(timestamp: ms(90100), zone: Zone.green);
    expect(stars.progress, 0);
  });

  test('noise after three stars resets progress but not earned stars', () {
    feed(stars, Zone.green, fromMs: 0, toMs: 180000);
    stars.onSample(timestamp: ms(180100), zone: Zone.red);
    expect(stars.stars, 3);
    expect(stars.progress, 0);
    expect(stars.earnedStarNow, isFalse);
  });

  test('changing the interval keeps earned stars and validates the value', () {
    feed(stars, Zone.green, fromMs: 0, toMs: 60000);
    feed(stars, Zone.green, fromMs: 60100, toMs: 62000);
    stars.setMinute(const Duration(seconds: 5));
    expect(stars.minute, const Duration(seconds: 5));
    expect(stars.stars, 1);
    expect(stars.progress, 0);
    expect(() => stars.setMinute(Duration.zero), throwsArgumentError);
    expect(() => QuietStars(minute: Duration.zero), throwsArgumentError);
  });
}
