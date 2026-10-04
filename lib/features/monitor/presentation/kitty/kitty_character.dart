// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/glow.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'kitty_mood.dart';
import 'kitty_painter.dart';

export 'kitty_mood.dart';

/// Mia, the kitty that shows how the room feels.
///
/// Pure presentation: the caller decides [mood] and [walkedAway] (see the
/// mood mapping of the monitor). With [reduceMotion] there is no walking
/// and no looping animation – changes only crossfade.
class KittyCharacter extends StatefulWidget {
  /// Creates Mia.
  const KittyCharacter({
    required this.mood,
    this.walkedAway = false,
    this.reduceMotion = false,
    super.key,
  });

  /// Current mood.
  final KittyMood mood;

  /// Whether Mia has left her stage because it was too loud for too long.
  final bool walkedAway;

  /// Disables walking and looping animations.
  final bool reduceMotion;

  /// Duration of the idle loop (blink, tail, purr, sobbing).
  static const Duration loopDuration = Duration(seconds: 4);

  /// Duration of walking off (or back onto) the stage.
  static const Duration walkDuration = Duration(milliseconds: 2400);

  /// Duration of crossfades.
  static const Duration fadeDuration = Duration(milliseconds: 350);

  @override
  State<KittyCharacter> createState() => _KittyCharacterState();
}

class _KittyCharacterState extends State<KittyCharacter>
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

  @override
  void initState() {
    super.initState();
    _syncLoop();
  }

  @override
  void didUpdateWidget(KittyCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) _syncLoop();
    if (oldWidget.walkedAway != widget.walkedAway ||
        oldWidget.reduceMotion != widget.reduceMotion) {
      final target = widget.walkedAway ? 1.0 : 0.0;
      if (widget.reduceMotion) {
        _walk.value = target;
      } else {
        // The returned future completes when the walk ends; nothing waits.
        _walk.animateTo(target).ignore();
      }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = widget.walkedAway
        ? l10n.kittyAwaySign
        : widget.mood.describe(l10n);
    return Semantics(
      label: label,
      image: true,
      container: true,
      child: ExcludeSemantics(
        child: ClipRect(
          child: widget.reduceMotion
              ? _buildStatic(l10n)
              : _buildAnimated(l10n),
        ),
      ),
    );
  }

  Widget _buildStatic(AppLocalizations l10n) => AnimatedSwitcher(
    duration: KittyCharacter.fadeDuration,
    child: _KittyScene(
      key: ValueKey((widget.mood, widget.walkedAway)),
      mood: widget.mood,
      phase: 0,
      walk: widget.walkedAway ? 1 : 0,
      signText: l10n.kittyAwaySign,
    ),
  );

  Widget _buildAnimated(AppLocalizations l10n) => AnimatedSwitcher(
    duration: KittyCharacter.fadeDuration,
    child: AnimatedBuilder(
      key: ValueKey(widget.mood),
      animation: Listenable.merge([_loop, _walk]),
      builder: (context, _) => _KittyScene(
        mood: widget.mood,
        phase: _loop.value,
        walk: Curves.easeInOut.transform(_walk.value),
        signText: l10n.kittyAwaySign,
      ),
    ),
  );
}

/// Mia's stage at one animation frame plus the "gone" sign.
class _KittyScene extends StatelessWidget {
  const _KittyScene({
    required this.mood,
    required this.phase,
    required this.walk,
    required this.signText,
    super.key,
  });

  final KittyMood mood;
  final double phase;
  final double walk;
  final String signText;

  @override
  Widget build(BuildContext context) {
    // The sign fades in during the last part of the walk.
    final signOpacity = ((walk - 0.6) / 0.4).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: KittyPainter(mood: mood, phase: phase, walk: walk),
        ),
        if (signOpacity > 0)
          Align(
            alignment: const Alignment(0, -0.1),
            child: Opacity(
              opacity: signOpacity,
              child: AwaySign(text: signText),
            ),
          ),
      ],
    );
  }
}

/// Small glowing sign that tells why Mia is gone.
class AwaySign extends StatelessWidget {
  /// Creates the sign.
  const AwaySign({required this.text, super.key});

  /// Text on the sign.
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.red, width: 2),
      boxShadow: Glow.shadows(AppColors.red, strength: 0.6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.pets_rounded, color: AppColors.red),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    ),
  );
}
