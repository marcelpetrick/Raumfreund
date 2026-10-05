// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/shop/domain/kitty_accessory.dart';

void main() {
  test('prices are positive and grow in catalog order', () {
    final prices = [for (final item in KittyAccessory.values) item.price];
    expect(prices.every((price) => price > 0), isTrue);
    for (var i = 1; i < prices.length; i++) {
      expect(prices[i], greaterThan(prices[i - 1]));
    }
  });
}
