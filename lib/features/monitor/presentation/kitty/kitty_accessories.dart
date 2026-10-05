// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:ui';

import '../../../../app/theme/glow.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../shop/domain/kitty_accessory.dart';
import 'kitty_body.dart';
import 'kitty_pose.dart';

/// German item names; shared by the screen-reader label and the shop.
extension KittyAccessoryNames on KittyAccessory {
  /// Localized name of the item.
  String describe(AppLocalizations l10n) => switch (this) {
    KittyAccessory.bow => l10n.accessoryBow,
    KittyAccessory.scarf => l10n.accessoryScarf,
    KittyAccessory.hat => l10n.accessoryHat,
    KittyAccessory.cushion => l10n.accessoryCushion,
    KittyAccessory.mouse => l10n.accessoryMouse,
  };
}

// Accessory colours. They are saturated enough to stand out from the pale fur
// but stay clear of the mood glow colours (green, yellow, red) so that they
// never look like a zone indicator.
const Color _bowPink = Color(0xFFFF5C93);
const Color _bowDark = Color(0xFFD63D78);
const Color _scarfViolet = Color(0xFF8E6CEF);
const Color _scarfStripe = Color(0xFFFFC2E2);
const Color _hatBlue = Color(0xFF3BA7FF);
const Color _hatStripe = Color(0xFFFFF6A8);
const Color _cushionRose = Color(0xFFB98CF5);
const Color _cushionTop = Color(0xFFD9BFFF);
const Color _mouseGrey = Color(0xFFC9C4E0);

/// Soft cushion under Mia, drawn before every body part so she sits on it.
void paintCushion(Canvas canvas, KittyLayer layer) {
  final rect = Rect.fromCenter(
    center: const Offset(120, 210),
    width: 136,
    height: 26,
  );
  drawFurOval(canvas, rect, layer, fill: _cushionRose);
  if (layer == KittyLayer.neon) return;
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(120, 207), width: 118, height: 16),
    Paint()..color = _cushionTop,
  );
  final tassel = Glow.stroke(_cushionTop, 3);
  canvas
    ..drawLine(const Offset(58, 210), const Offset(53, 216), tassel)
    ..drawLine(const Offset(182, 210), const Offset(187, 216), tassel);
}

/// Knitted scarf: a band around the neck plus one hanging end.
///
/// Drawn between body and head, so the chin covers its upper edge and the
/// face stays completely free.
void paintScarf(Canvas canvas, KittyLayer layer) {
  final band = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(120, 150), width: 92, height: 20),
        const Radius.circular(10),
      ),
    );
  final tail = Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTRB(126, 152, 146, 184),
        const Radius.circular(6),
      ),
    );
  drawFurPath(canvas, tail, layer, fill: _scarfViolet);
  drawFurPath(canvas, band, layer, fill: _scarfViolet);
  if (layer == KittyLayer.neon) return;
  final stripe = Glow.stroke(_scarfStripe, 3);
  canvas
    ..drawLine(const Offset(127, 172), const Offset(145, 172), stripe)
    ..drawLine(const Offset(127, 179), const Offset(145, 179), stripe);
  for (var x = 84.0; x < 160; x += 14) {
    canvas.drawLine(Offset(x, 144), Offset(x + 4, 157), stripe);
  }
}

/// Bow on the left ear. It follows the ear as it droops, so it sits on the
/// ear in every mood.
void paintBow(Canvas canvas, KittyPose pose, KittyLayer layer) {
  final anchor = Offset.lerp(
    const Offset(84, 38),
    const Offset(52, 70),
    pose.earDroop,
  )!;
  canvas
    ..save()
    ..translate(anchor.dx, anchor.dy)
    ..rotate(-0.5 - 0.35 * pose.earDroop);
  for (final side in const [-1.0, 1.0]) {
    final loop = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(side * 12, -13, side * 20, -7)
      ..quadraticBezierTo(side * 22, 0, side * 20, 7)
      ..quadraticBezierTo(side * 12, 13, 0, 0)
      ..close();
    drawFurPath(canvas, loop, layer, fill: _bowPink);
    if (layer == KittyLayer.fill) {
      canvas.drawLine(
        Offset.zero,
        Offset(side * 15, 0),
        Glow.stroke(_bowDark, 2),
      );
    }
  }
  drawFurOval(
    canvas,
    Rect.fromCenter(center: Offset.zero, width: 10, height: 11),
    layer,
    fill: _bowDark,
  );
  canvas.restore();
}

/// Small party hat on top of the head, tilted with the ear droop.
void paintHat(Canvas canvas, KittyPose pose, KittyLayer layer) {
  const base = Offset(120, 44);
  canvas
    ..save()
    ..translate(base.dx, base.dy)
    ..rotate(-0.3 * pose.earDroop);
  final cone = Path()
    ..moveTo(-17, 0)
    ..lineTo(0, -38)
    ..lineTo(17, 0)
    ..close();
  drawFurPath(canvas, cone, layer, fill: _hatBlue);
  if (layer == KittyLayer.fill) {
    canvas
      ..save()
      ..clipPath(cone);
    final stripe = Glow.stroke(_hatStripe, 4);
    for (final y in const [-8.0, -18.0, -28.0]) {
      canvas.drawLine(Offset(-20, y + 6), Offset(20, y - 6), stripe);
    }
    canvas.restore();
  }
  drawFurOval(
    canvas,
    Rect.fromCircle(center: const Offset(0, -39), radius: 5),
    layer,
    fill: _bowPink,
  );
  canvas.restore();
}

/// Toy mouse on the stage next to Mia's paws.
///
/// Drawn in stage coordinates, not in Mia's: a toy stays behind when she
/// runs away.
void paintMouse(Canvas canvas) {
  const c = Offset(40, 208);
  final body = Rect.fromCenter(center: c, width: 30, height: 18);
  final outline = Glow.stroke(KittyColors.neon, 2.5);
  final tail = Path()
    ..moveTo(c.dx - 14, c.dy + 2)
    ..cubicTo(c.dx - 30, c.dy + 4, c.dx - 28, c.dy - 10, c.dx - 38, c.dy - 6);
  canvas
    ..drawOval(body, Glow.halo(KittyColors.neon, sigma: 5, alpha: 0.5))
    ..drawPath(tail, Glow.stroke(KittyColors.innerEar, 2))
    ..drawOval(body, Paint()..color = _mouseGrey)
    ..drawOval(body, outline);
  for (final dx in const [2.0, 11.0]) {
    final ear = Rect.fromCircle(center: c.translate(dx, -8), radius: 5);
    canvas
      ..drawOval(ear, Paint()..color = KittyColors.innerEar)
      ..drawOval(ear, outline);
  }
  canvas
    ..drawCircle(c.translate(8, -1), 1.6, Paint()..color = KittyColors.ink)
    ..drawCircle(c.translate(15, 1), 2, Paint()..color = KittyColors.nose);
}
