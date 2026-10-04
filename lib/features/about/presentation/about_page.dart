// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glow_panel.dart';
import '../../../shared/widgets/night_sky_background.dart';
import '../domain/app_info.dart';

/// Privacy, build, project and licence information.
class AboutPage extends StatelessWidget {
  /// Creates the About page.
  const AboutPage({required this.info, super.key});

  /// Information of the running Android package.
  final AppInfo info;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return NightSkyBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.aboutTitle)),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _identity(context, l10n),
              const SizedBox(height: 16),
              _textSection(
                context,
                Icons.privacy_tip_outlined,
                l10n.aboutPrivacyHeading,
                l10n.aboutPrivacyBody,
              ),
              const SizedBox(height: 16),
              _textSection(
                context,
                Icons.speed_rounded,
                l10n.aboutMeasurementHeading,
                l10n.aboutMeasurementBody,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: l10n.appTitle,
                  applicationVersion: info.versionName,
                  applicationLegalese: l10n.aboutLicenseValue,
                ),
                icon: const Icon(Icons.description_outlined),
                label: Text(l10n.aboutLicensesButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identity(BuildContext context, AppLocalizations l10n) => GlowPanel(
    color: AppColors.green,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.appTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(l10n.aboutTagline),
        const SizedBox(height: 16),
        _row(l10n.aboutVersion, info.versionName),
        _row(
          l10n.aboutBuild,
          l10n.aboutBuildValue(info.buildNumber, info.gitCommit),
        ),
        _row(l10n.aboutAuthor, 'Marcel Petrick'),
        _row(l10n.aboutEmail, 'mail@marcelpetrick.it'),
        _row(l10n.aboutProject, 'github.com/marcelpetrick/Raumfreund'),
        _row(l10n.aboutLicense, l10n.aboutLicenseValue),
      ],
    ),
  );

  Widget _textSection(
    BuildContext context,
    IconData icon,
    String title,
    String body,
  ) => GlowPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon), const SizedBox(width: 10), Text(title)]),
        const SizedBox(height: 10),
        Text(body),
      ],
    ),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 88, child: Text(label)),
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}
