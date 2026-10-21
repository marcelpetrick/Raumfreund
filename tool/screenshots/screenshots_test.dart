// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

// Renders the README screenshots of every monitor state and of the four UI
// languages from the real widgets (Roboto and Material Icons of the pinned
// SDK, Noto Sans CJK for Chinese). Not part of the test suite: run it
// through tool/render_screenshots.sh, which writes docs/screenshots/*.png.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/app/theme/app_theme.dart';
import 'package:raumfreund/features/monitor/domain/level_history_point.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_page.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_view_data.dart';
import 'package:raumfreund/features/settings/application/language_controller.dart';
import 'package:raumfreund/features/settings/domain/app_language.dart';
import 'package:raumfreund/features/settings/domain/app_settings.dart';
import 'package:raumfreund/features/settings/presentation/settings_page.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';
import 'package:raumfreund/l10n/generated/app_localizations.dart';

import '../../test/fakes/in_memory_language_repository.dart';
import '../../test/goldens/golden_fonts.dart';

/// Size of one screenshot in physical pixels.
const Size _shotSize = Size(540, 1290);

/// Pixel ratio of the screenshots (360 x 860 logical pixels).
const double _ratio = 1.5;

/// Where the PNGs go (set by tool/render_screenshots.sh).
final String _outDir =
    Platform.environment['RAUMFREUND_SCREENSHOT_DIR'] ?? 'docs/screenshots';

/// A font with Simplified Chinese glyphs; the test environment has none.
/// Overridable with RAUMFREUND_CJK_FONT (a .ttf, .otf or .ttc file).
final String _cjkFont =
    Platform.environment['RAUMFREUND_CJK_FONT'] ??
    '/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc';

const String _cjkFamily = 'NotoSansCJK';

final _boundary = GlobalKey();

/// One screenshot: the page shown (optionally after [before]), its
/// language and how long to animate first.
typedef _Shot = ({
  String name,
  Widget page,
  Widget? before,
  Duration settle,
  Locale locale,
});

void main() {
  testWidgets('renders all monitor states', (tester) async {
    await loadGoldenFonts();
    await _loadCjkFont();
    tester.view
      ..physicalSize = _shotSize
      ..devicePixelRatio = _ratio;
    addTearDown(tester.view.reset);
    final images = <String, ui.Image>{};
    for (final shot in _shots()) {
      images[shot.name] = await _render(tester, shot);
    }
    await _writeOverview(tester, [
      for (final name in _overview) images[name]!,
    ], 'overview');
    await _writeOverview(tester, [
      for (final name in _languages) images[name]!,
    ], 'languages');
  });
}

Future<void> _loadCjkFont() async {
  final file = File(_cjkFont);
  if (!file.existsSync()) {
    fail('No CJK font at $_cjkFont; set RAUMFREUND_CJK_FONT');
  }
  final bytes = file.readAsBytesSync();
  await (FontLoader(
    _cjkFamily,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

/// Button labels set a text style without a family; Android falls back to
/// Roboto there, the test environment to its box font. Naming Roboto for
/// the buttons makes the screenshots match a device. Chinese glyphs fall
/// back to Noto Sans CJK, as on Android.
ThemeData _theme() {
  final base = buildAppTheme();
  ButtonStyle? roboto(ButtonStyle? style) => style?.copyWith(
    textStyle: WidgetStateProperty.resolveWith(
      (states) => style.textStyle
          ?.resolve(states)
          ?.copyWith(fontFamily: 'Roboto', fontFamilyFallback: [_cjkFamily]),
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamilyFallback: [_cjkFamily]),
    filledButtonTheme: FilledButtonThemeData(
      style: roboto(base.filledButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: roboto(base.outlinedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: roboto(base.textButtonTheme.style),
    ),
  );
}

/// Order of the two rows of the state overview.
const _overview = [
  'idle',
  'green',
  'yellow',
  'red',
  'away',
  'sleeping',
  'wakeup',
  'error',
];

/// The language row: Settings with the language list, then the monitor in
/// English, Croatian and Chinese.
const _languages = ['settings', 'english', 'croatian', 'chinese'];

List<_Shot> _shots() {
  const loop = Duration(milliseconds: 1500);
  final sleeping = _data(MonitorPhase.sleeping, null, levelDb: null);
  return [
    _shot('idle', _data(MonitorPhase.idle, null, levelDb: null), loop),
    _shot('green', _data(MonitorPhase.measuring, Zone.green), loop),
    _shot('yellow', _data(MonitorPhase.measuring, Zone.yellow), loop),
    _shot('red', _data(MonitorPhase.measuring, Zone.red), loop),
    _shot('away', _data(MonitorPhase.measuring, Zone.red, away: true), loop),
    _shot('sleeping', sleeping, loop),
    // Mid wake-up: after the sleepy lead she yawns and starts to stretch.
    (
      name: 'wakeup',
      page: _monitor(_data(MonitorPhase.measuring, Zone.green)),
      before: _monitor(sleeping),
      settle: const Duration(milliseconds: 1000),
      locale: const Locale('de'),
    ),
    _shot('error', _data(MonitorPhase.error, null, levelDb: null), loop),
    (
      name: 'settings',
      page: _settings(),
      before: null,
      settle: const Duration(milliseconds: 400),
      locale: const Locale('de'),
    ),
    _shot('english', _data(MonitorPhase.measuring, Zone.green), loop, 'en'),
    _shot('croatian', _data(MonitorPhase.measuring, Zone.yellow), loop, 'hr'),
    _shot('chinese', _data(MonitorPhase.measuring, Zone.red), loop, 'zh'),
  ];
}

_Shot _shot(
  String name,
  MonitorViewData data,
  Duration settle, [
  String language = 'de',
]) => (
  name: name,
  page: _monitor(data),
  before: null,
  settle: settle,
  locale: Locale(language),
);

MonitorViewData _data(
  MonitorPhase phase,
  Zone? zone, {
  double? levelDb = 0,
  bool away = false,
}) {
  final level = switch (zone) {
    Zone.green => 46.0,
    Zone.yellow => 68.0,
    Zone.red => 88.0,
    null => levelDb,
  };
  return MonitorViewData(
    phase: phase,
    thresholds: Thresholds.defaults,
    levelDb: level,
    zone: zone,
    history: _history(zone),
    alarmSecondsRemaining: switch (zone) {
      Zone.yellow => 6,
      Zone.red when !away => 3,
      _ => null,
    },
    alarmFired: away,
    kittyWalkedAway: away,
    kittyAccessories: const {KittyAccessory.bow},
    stars: 3,
    walletStars: 12,
    starProgress: 0.6,
    error: phase == MonitorPhase.error ? MonitorErrorKind.microphoneBusy : null,
  );
}

/// Ten calm minutes that end in the current zone.
List<LevelHistoryPoint> _history(Zone? zone) {
  final end = switch (zone) {
    Zone.yellow => 68.0,
    Zone.red => 88.0,
    _ => 46.0,
  };
  return [
    for (var i = 0; i <= 60; i++)
      LevelHistoryPoint(
        timestamp: Duration(seconds: i * 10),
        levelDb: i < 54
            ? 42 + 6 * math.sin(i / 4) + (i % 7 == 0 ? 9 : 0)
            : 46 + (end - 46) * (i - 53) / 7,
      ),
  ];
}

Widget _app(Widget page, Locale locale) => RepaintBoundary(
  key: _boundary,
  child: MaterialApp(
    theme: _theme(),
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: page,
  ),
);

Widget _monitor(MonitorViewData data) => MonitorPage(
  data: data,
  onToggleMeasurement: () {},
  onRetry: () {},
  onOpenAndroidSettings: () {},
  onOpenSettings: () async {},
  onOpenAbout: () async {},
  onOpenShop: () async {},
);

Widget _settings() => SettingsPage(
  initialSettings: AppSettings.defaults,
  onSave: (_) async => true,
  languageController: LanguageController(
    InMemoryLanguageRepository(AppLanguage.german),
  ),
);

Future<ui.Image> _render(WidgetTester tester, _Shot shot) async {
  // A fresh tree per shot, so no animation state leaks between states.
  await tester.pumpWidget(const SizedBox.shrink());
  final before = shot.before;
  if (before != null) {
    await tester.pumpWidget(_app(before, shot.locale));
    await tester.pump(const Duration(milliseconds: 600));
  }
  await tester.pumpWidget(_app(shot.page, shot.locale));
  await tester.pump(shot.settle);
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_boundary),
  );
  final image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: _ratio),
  ))!;
  await _writePng(tester, image, '$_outDir/${shot.name}.png');
  return image;
}

/// Rows of four screenshots at 3/4 size, written as [name].png.
Future<void> _writeOverview(
  WidgetTester tester,
  List<ui.Image> images,
  String name,
) async {
  final rows = (images.length / 4).ceil();
  const scale = 0.75;
  const gap = 12.0;
  final w = _shotSize.width * scale;
  final h = _shotSize.height * scale;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..drawRect(
      Rect.fromLTWH(0, 0, 4 * w + 3 * gap, rows * h + (rows - 1) * gap),
      Paint()..color = const Color(0xFF0B0620),
    );
  for (var i = 0; i < images.length; i++) {
    final image = images[i];
    final dst = Rect.fromLTWH((i % 4) * (w + gap), (i ~/ 4) * (h + gap), w, h);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }
  final overview = (await tester.runAsync(
    () => recorder.endRecording().toImage(
      (4 * w + 3 * gap).round(),
      (rows * h + (rows - 1) * gap).round(),
    ),
  ))!;
  await _writePng(tester, overview, '$_outDir/$name.png');
}

Future<void> _writePng(WidgetTester tester, ui.Image image, String path) =>
    tester.runAsync(() async {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    });
