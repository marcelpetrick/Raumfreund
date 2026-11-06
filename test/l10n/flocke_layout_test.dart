// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raumfreund/features/monitor/domain/thresholds.dart';
import 'package:raumfreund/features/monitor/domain/zone.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_page.dart';
import 'package:raumfreund/features/monitor/presentation/monitor_view_data.dart';
import 'package:raumfreund/features/settings/domain/app_language.dart';
import 'package:raumfreund/features/shop/application/shop_controller.dart';
import 'package:raumfreund/features/shop/domain/pet_kind.dart';
import 'package:raumfreund/features/shop/domain/star_wallet.dart';
import 'package:raumfreund/features/shop/presentation/shop_page.dart';
import 'package:raumfreund/l10n/generated/app_localizations.dart';

import '../fakes/in_memory_shop_repository.dart';
import '../shared/widgets/test_app.dart';

void main() {
  for (final language in AppLanguage.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Flocke fits ${language.code} at ${scale}x', (tester) async {
        final locale = Locale(language.code);
        final l10n = lookupAppLocalizations(locale);
        setScreenSize(tester, const Size(360, 780));
        Future<void> show(Widget child) async {
          await tester.pumpWidget(
            testApp(
              child,
              scaffold: false,
              disableAnimations: true,
              textScale: scale,
              locale: locale,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }

        for (final phase in [
          MonitorPhase.sleeping,
          MonitorPhase.starting,
          MonitorPhase.measuring,
        ]) {
          await show(
            MonitorPage(
              data: MonitorViewData(
                phase: phase,
                thresholds: Thresholds.defaults,
                pet: PetKind.flocke,
                waking: phase == MonitorPhase.starting,
                zone: phase == MonitorPhase.measuring ? Zone.red : null,
                kittyWalkedAway: phase == MonitorPhase.measuring,
              ),
              onToggleMeasurement: () {},
              onOpenSettings: () async {},
              onOpenAbout: () async {},
              onOpenShop: () async {},
            ),
          );
          final label = switch (phase) {
            MonitorPhase.sleeping => l10n.flockeStatusSleeping,
            MonitorPhase.starting => l10n.flockeStatusWaking,
            _ => l10n.flockeAwaySign,
          };
          expect(find.text(label), findsOneWidget);
        }
        final shop = ShopController(
          InMemoryShopRepository(
            StarWallet(balance: 10).selectPet(PetKind.flocke),
          ),
        );
        addTearDown(shop.dispose);
        await shop.load();
        await show(ShopPage(controller: shop));
        expect(find.text(l10n.flockeShopLevel(3)), findsOneWidget);
        await tester.ensureVisible(find.text(l10n.shopPetFlocke));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
