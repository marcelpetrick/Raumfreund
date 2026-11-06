// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glow_panel.dart';
import '../../../shared/widgets/night_sky_background.dart';
import '../../monitor/presentation/husky/husky_character.dart';
import '../../monitor/presentation/kitty/kitty_accessories.dart';
import '../../monitor/presentation/kitty/kitty_character.dart';
import '../application/shop_controller.dart';
import '../domain/kitty_accessory.dart';
import '../domain/pet_kind.dart';
import '../domain/star_wallet.dart';

/// The star shop: children spend quiet-minute stars on items for Mia.
///
/// It only renders [controller] and forwards taps; all rules (price, one-time
/// purchase, equipped subset of owned) live in the wallet. Buying asks for a
/// short confirmation so a stray tap never spends stars.
class ShopPage extends StatelessWidget {
  /// Creates the shop page for [controller].
  const ShopPage({required this.controller, super.key});

  /// Wallet owner; the page rebuilds whenever it changes.
  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NightSkyBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.shopTitle)),
        body: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _ShopBody(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _ShopBody extends StatelessWidget {
  const _ShopBody({required this.controller});

  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (controller.isLoading) {
      return Center(
        child: Semantics(
          label: l10n.shopLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: _content(l10n),
          ),
        ),
      ],
    );
  }

  Widget _content(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Header(wallet: controller.wallet, isReady: controller.isReady),
      _PetSelector(controller: controller),
      if (controller.loadFailed) _Hint(text: l10n.shopLoadFailed),
      if (controller.saveFailed)
        _Hint(
          text: l10n.shopSaveFailed,
          actionLabel: l10n.shopDismiss,
          onAction: controller.clearSaveError,
        ),
      const SizedBox(height: 16),
      for (final item in KittyAccessory.values) ...[
        _ItemCard(controller: controller, item: item),
        const SizedBox(height: 12),
      ],
    ],
  );
}

class _PetSelector extends StatelessWidget {
  const _PetSelector({required this.controller});
  final ShopController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wallet = controller.wallet;
    return RadioGroup<PetKind>(
      groupValue: wallet.selectedPet,
      onChanged: (pet) {
        if (pet != null) controller.selectPet(pet);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            l10n.shopPetHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          RadioListTile<PetKind>(
            title: Text(l10n.shopPetMia),
            value: PetKind.mia,
            enabled: controller.isReady,
          ),
          RadioListTile<PetKind>(
            title: Text(l10n.shopPetFlocke),
            subtitle: wallet.isFlockeUnlocked
                ? null
                : Text(l10n.shopPetFlockeLocked),
            value: PetKind.flocke,
            enabled: controller.isReady && wallet.isFlockeUnlocked,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({required this.wallet, required this.isReady});

  final StarWallet wallet;
  final bool isReady;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> with SingleTickerProviderStateMixin {
  late final AnimationController _dance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _dance.isAnimating) {
      _dance.reset();
    }
  }

  @override
  void didUpdateWidget(_Header oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallet.selectedPet != widget.wallet.selectedPet) {
      _dance.reset();
    }
  }

  @override
  void dispose() {
    _dance.dispose();
    super.dispose();
  }

  void _startDance() {
    if (MediaQuery.disableAnimationsOf(context)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.wallet.selectedPet == PetKind.flocke
                ? AppLocalizations.of(context).flockeDanceReduced
                : AppLocalizations.of(context).shopDanceReduced,
          ),
        ),
      );
    } else {
      _dance.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wallet = widget.wallet;
    final unlocked = widget.isReady && wallet.level >= 2;
    return GlowPanel(
      color: AppColors.yellow,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const ExcludeSemantics(
                child: Icon(Icons.star_rounded, color: AppColors.yellow),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.shopBalance(wallet.balance),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          if (widget.isReady) ...[
            const SizedBox(height: 12),
            Text(
              wallet.selectedPet == PetKind.flocke
                  ? l10n.flockeShopLevel(wallet.level)
                  : l10n.shopLevel(wallet.level),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              l10n.shopLevelProgress(
                wallet.starsTowardNextLevel,
                StarWallet.starsPerLevel,
              ),
            ),
            const SizedBox(height: 6),
            ExcludeSemantics(
              child: LinearProgressIndicator(
                value: wallet.starsTowardNextLevel / StarWallet.starsPerLevel,
              ),
            ),
          ],
          _dancingKitty(context),
          if (widget.isReady) ...[
            OutlinedButton.icon(
              onPressed: unlocked ? _startDance : null,
              icon: const Icon(Icons.celebration_outlined),
              label: Text(
                wallet.selectedPet == PetKind.flocke
                    ? l10n.flockeDance
                    : l10n.shopDance,
              ),
            ),
            if (!unlocked)
              Text(
                wallet.selectedPet == PetKind.flocke
                    ? l10n.flockeDanceLocked
                    : l10n.shopDanceLocked,
              ),
          ],
        ],
      ),
    );
  }

  Widget _dancingKitty(BuildContext context) => SizedBox(
    height: 220,
    child: AnimatedBuilder(
      animation: _dance,
      builder: (context, _) {
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        if (widget.wallet.selectedPet == PetKind.flocke) {
          return HuskyCharacter(
            mood: KittyMood.idle,
            semanticLabel: AppLocalizations.of(context).flockeIdle,
            awayLabel: AppLocalizations.of(context).flockeAwaySign,
            accessories: widget.wallet.equipped,
            reduceMotion: reduceMotion,
            danceProgress: !reduceMotion && _dance.isAnimating
                ? _dance.value
                : null,
          );
        }
        final value = _dance.value;
        final envelope = math.sin(math.pi * value);
        final wobble = math.sin(value * math.pi * 8) * envelope;
        return Transform.rotate(
          angle: 0.13 * wobble,
          child: KittyCharacter(
            mood: KittyMood.idle,
            accessories: widget.wallet.equipped,
            reduceMotion: reduceMotion,
          ),
        );
      },
    ),
  );
}

/// Non-blocking notice; never hides the shop itself.
class _Hint extends StatelessWidget {
  const _Hint({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GlowPanel(
        color: AppColors.yellow,
        glowStrength: 0,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded),
                const SizedBox(width: 10),
                Expanded(child: Text(text)),
              ],
            ),
            if (onAction != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text(actionLabel!),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.controller, required this.item});

  final ShopController controller;
  final KittyAccessory item;

  @override
  Widget build(BuildContext context) {
    final wallet = controller.wallet;
    return GlowPanel(
      color: wallet.equipped.contains(item)
          ? AppColors.green
          : AppColors.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ItemSummary(item: item, wallet: wallet),
          const SizedBox(height: 12),
          _ItemAction(controller: controller, item: item),
        ],
      ),
    );
  }
}

/// Name, price and state as one spoken sentence; the visible parts are
/// excluded from semantics so nothing is announced twice.
class _ItemSummary extends StatelessWidget {
  const _ItemSummary({required this.item, required this.wallet});

  final KittyAccessory item;
  final StarWallet wallet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = item.describe(l10n);
    final price = l10n.shopPrice(item.price);
    final state = _stateText(l10n);
    return Semantics(
      container: true,
      label: [name, price, ?state].join(', '),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleMedium),
            _IconText(
              icon: Icons.star_rounded,
              text: price,
              color: AppColors.yellow,
            ),
            if (state != null)
              _IconText(icon: Icons.check_circle_outline_rounded, text: state),
          ],
        ),
      ),
    );
  }

  // A text next to the icon keeps the state readable without colour.
  String? _stateText(AppLocalizations l10n) {
    if (wallet.equipped.contains(item)) {
      return wallet.selectedPet == PetKind.flocke
          ? l10n.flockeShopWorn
          : l10n.shopWorn;
    }
    if (wallet.owned.contains(item)) return l10n.shopOwned;
    return null;
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(width: 4),
      Flexible(child: Text(text)),
    ],
  );
}

class _ItemAction extends StatelessWidget {
  const _ItemAction({required this.controller, required this.item});

  final ShopController controller;
  final KittyAccessory item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wallet = controller.wallet;
    const size = Size(48, 48);
    if (wallet.equipped.contains(item)) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: size),
        onPressed: () => controller.toggleEquipped(item),
        child: Text(l10n.shopUnequip),
      );
    }
    if (wallet.owned.contains(item)) {
      return FilledButton(
        style: FilledButton.styleFrom(minimumSize: size),
        onPressed: () => controller.toggleEquipped(item),
        child: Text(
          wallet.selectedPet == PetKind.flocke
              ? l10n.flockeShopEquip
              : l10n.shopEquip,
        ),
      );
    }
    final missing = item.price - wallet.balance;
    final canBuy = controller.isReady && missing <= 0;
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: size),
      onPressed: canBuy ? () => _confirmAndBuy(context) : null,
      child: Text(missing > 0 ? l10n.shopMissing(missing) : l10n.shopBuy),
    );
  }

  Future<void> _confirmAndBuy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final title = l10n.shopConfirmTitle(
      item.describe(l10n),
      l10n.shopPrice(item.price),
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.shopConfirmCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.shopConfirmBuy),
          ),
        ],
      ),
    );
    // The controller refuses a purchase that is no longer possible; the page
    // then simply keeps showing the unchanged wallet.
    if (confirmed ?? false) controller.buy(item);
  }
}
