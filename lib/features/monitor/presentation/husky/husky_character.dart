// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../shop/domain/kitty_accessory.dart';
import '../kitty/kitty_accessories.dart';
import '../kitty/kitty_character.dart' show AwaySign, KittyCharacter;
import '../kitty/kitty_mood.dart';
import 'husky_painter.dart';

/// Flocke reacts and animates with the same timing as Mia.
class HuskyCharacter extends StatefulWidget {
  /// Creates Flocke; callers supply translated mood and absence labels.
  const HuskyCharacter({
    required this.mood,
    required this.semanticLabel,
    required this.awayLabel,
    this.walkedAway = false,
    this.reduceMotion = false,
    this.wakeUp = false,
    this.danceProgress,
    this.accessories = const <KittyAccessory>{},
    super.key,
  });

  /// Room mood, shared with Mia's visual state model.
  final KittyMood mood;

  /// Translated screen-reader description of the current mood.
  final String semanticLabel;

  /// Translated label displayed and spoken while Flocke is away.
  final String awayLabel;

  /// Whether Flocke has left because the room was too loud.
  final bool walkedAway;

  /// Whether animation is disabled for accessibility.
  final bool reduceMotion;

  /// Whether leaving sleep should animate a successful wake-up.
  final bool wakeUp;

  /// Optional shop dance progress from zero to one.
  final double? danceProgress;

  /// Equipped cosmetic items shared with Mia.
  final Set<KittyAccessory> accessories;

  @override
  State<HuskyCharacter> createState() => _HuskyCharacterState();
}

class _HuskyCharacterState extends State<HuskyCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: KittyCharacter.loopDuration,
  );
  late final AnimationController _walk = AnimationController(
    vsync: this,
    duration: KittyCharacter.walkDuration,
    value: widget.walkedAway ? 1 : 0,
  );
  late final AnimationController _wake = AnimationController(
    vsync: this,
    duration: KittyCharacter.wakeDuration,
  );

  @override
  void initState() {
    super.initState();
    // A late-mounted pet may already be away; do not animate from the stage.
    _walk.value = widget.walkedAway ? 1 : 0;
    _syncLoop();
  }

  @override
  void didUpdateWidget(HuskyCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) _syncLoop();
    _syncWake(oldWidget.mood);
    if (oldWidget.walkedAway != widget.walkedAway ||
        oldWidget.reduceMotion != widget.reduceMotion) {
      final target = widget.walkedAway ? 1.0 : 0.0;
      if (widget.reduceMotion) {
        _walk.value = target;
      } else {
        _walk
            .animateTo(
              target,
              duration: widget.walkedAway
                  ? KittyCharacter.runDuration
                  : KittyCharacter.walkDuration,
            )
            .ignore();
      }
    }
  }

  void _syncWake(KittyMood oldMood) {
    if (widget.mood == KittyMood.sleeping ||
        widget.reduceMotion ||
        widget.walkedAway) {
      _wake
        ..stop()
        ..value = 0;
    } else if (oldMood == KittyMood.sleeping && widget.wakeUp) {
      _wake.forward(from: 0).ignore();
    }
  }

  void _syncLoop() {
    if (widget.reduceMotion) {
      _loop
        ..stop()
        ..value = 0;
    } else {
      _loop.repeat().ignore();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _walk.dispose();
    _wake.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: _label(AppLocalizations.of(context)),
    image: true,
    container: true,
    child: ExcludeSemantics(
      child: ClipRect(
        child: widget.reduceMotion ? _staticScene() : _animatedScene(),
      ),
    ),
  );

  String _label(AppLocalizations l10n) {
    final base = widget.walkedAway ? widget.awayLabel : widget.semanticLabel;
    final items = [
      for (final item in KittyAccessory.values)
        if (widget.accessories.contains(item) &&
            (!widget.walkedAway || item == KittyAccessory.mouse))
          item.describe(l10n),
    ];
    if (items.isEmpty) return base;
    final description = widget.walkedAway
        ? items.join(', ')
        : l10n.flockeWearing(items.join(', '));
    return '$base. $description';
  }

  Widget _staticScene() => AnimatedSwitcher(
    duration: KittyCharacter.fadeDuration,
    child: _HuskyScene(
      key: ValueKey((widget.mood, widget.walkedAway)),
      mood: widget.mood,
      phase: 0,
      walk: widget.walkedAway ? 1 : 0,
      running: false,
      accessories: widget.accessories,
      awayLabel: widget.awayLabel,
    ),
  );

  Widget _animatedScene() {
    final mood = widget.mood;
    return AnimatedSwitcher(
      duration: KittyCharacter.fadeDuration,
      child: AnimatedBuilder(
        key: ValueKey(mood),
        animation: Listenable.merge([_loop, _walk, _wake]),
        builder: (context, _) => _HuskyScene(
          mood: mood,
          phase: _loop.value,
          walk: Curves.easeInOut.transform(_walk.value),
          running: widget.walkedAway,
          accessories: widget.accessories,
          awayLabel: widget.awayLabel,
          wake: _wake.isAnimating ? _wake.value : null,
          danceProgress:
              widget.walkedAway ||
                  mood == KittyMood.sleeping ||
                  _wake.isAnimating
              ? null
              : widget.danceProgress,
        ),
      ),
    );
  }
}

class _HuskyScene extends StatelessWidget {
  const _HuskyScene({
    required this.mood,
    required this.phase,
    required this.walk,
    required this.running,
    required this.accessories,
    required this.awayLabel,
    this.wake,
    this.danceProgress,
    super.key,
  });

  final KittyMood mood;
  final double phase;
  final double walk;
  final bool running;
  final Set<KittyAccessory> accessories;
  final String awayLabel;
  final double? wake;
  final double? danceProgress;

  @override
  Widget build(BuildContext context) {
    final signOpacity = ((walk - 0.6) / 0.4).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: HuskyPainter(
            mood: mood,
            phase: phase,
            walk: walk,
            running: running,
            accessories: accessories,
            wake: wake,
            danceProgress: danceProgress,
          ),
        ),
        if (signOpacity > 0)
          Align(
            alignment: const Alignment(0, -0.1),
            child: Opacity(
              opacity: signOpacity,
              child: AwaySign(text: awayLabel),
            ),
          ),
      ],
    );
  }
}
