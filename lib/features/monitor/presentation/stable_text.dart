// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

/// Text slot whose height is the maximum over all [variants].
///
/// Zone changes swap headline, alarm and star texts of different length. If
/// the slot followed the current text, wrapping would make everything below
/// jump. All variants are therefore laid out invisibly at the current width
/// and text scale, so the slot never needs hard-coded pixel heights.
///
/// Hidden variants are plain [RichText]s, not [Text]s, so they stay invisible
/// to widget finders as well. They use [Visibility] without
/// `maintainSemantics`, so only the visible [text] reaches the semantics tree.
/// There is intentionally no size animation.
class StableText extends StatelessWidget {
  /// Creates a slot showing [text] and reserving the room of every variant.
  const StableText({
    required this.text,
    required this.variants,
    this.style,
    this.textAlign = TextAlign.start,
    super.key,
  });

  /// Text shown right now; may be empty.
  final String text;

  /// Every text this slot can show; used only for measuring.
  final List<String> variants;

  /// Text style shared by the visible and the measuring texts.
  final TextStyle? style;

  /// Horizontal alignment of the text inside the slot.
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final centered = textAlign == TextAlign.center;
    // Same style resolution as Text, so measuring and visible text agree.
    final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
    return Stack(
      // Passthrough keeps the incoming tight width, so wrapping matches the
      // surrounding layout.
      fit: StackFit.passthrough,
      alignment: centered ? Alignment.topCenter : AlignmentDirectional.topStart,
      children: [
        for (final variant in variants)
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: RichText(
              text: TextSpan(text: variant, style: effectiveStyle),
              textAlign: textAlign,
              textScaler: MediaQuery.textScalerOf(context),
            ),
          ),
        Text(text, style: style, textAlign: textAlign),
      ],
    );
  }
}
