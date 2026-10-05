// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Cosmetic items children can buy for Mia with quiet-minute stars.
///
/// Shared contract between the shop (catalog, wallet, inventory) and the
/// kitty renderer, which draws one painter layer per equipped item. The
/// order is the catalog order; [price] grows so that later items need a few
/// quiet sessions. Items are purely decorative: they never change zones,
/// alarms or measurement.
enum KittyAccessory {
  /// A bow on the left ear.
  bow(price: 3),

  /// A knitted scarf around the neck.
  scarf(price: 5),

  /// A small party hat between the ears.
  hat(price: 8),

  /// A soft cushion Mia sits on.
  cushion(price: 10),

  /// A toy mouse next to her paws.
  mouse(price: 12);

  const KittyAccessory({required this.price});

  /// Price in quiet-minute stars; always positive.
  final int price;
}
