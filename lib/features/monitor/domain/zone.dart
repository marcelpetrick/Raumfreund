// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

/// Traffic-light zone of the estimated sound level.
enum Zone {
  /// Below the yellow threshold – pleasant.
  green,

  /// From the yellow threshold up to (excluding) the red threshold.
  yellow,

  /// At or above the red threshold.
  red,
}
