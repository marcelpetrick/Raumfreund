<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# To the moon, aka Google Play

This is the owner's step-by-step guide to getting Raumfreund into Google Play.
Work through it top to bottom and tick the boxes as you go. The background is
in [`play-store.md`](play-store.md) and [`releasing.md`](releasing.md).

**What already works:** the app targets API 36, runs on Android 7.0+ and has
no Internet permission, tracking or stored audio. The tag-triggered Release
workflow builds a signed APK and AAB. What is missing is mostly account,
key, listing and policy work that only you can do.

**Mind the dates:** Google changes its Play rules often. Fees, tester counts
and form questions below were correct as far as known in November 2026. When
the Play Console says something different, the Play Console wins.

Legend: 🧑 you must do it, 🤖 an agent can do it in the repository.

## Step 0: Decide who the app is for (🧑, 15 min)

Decide this first, because it changes the listing, the screenshots and the
forms in step 6.

- [ ] **Adults only** (parents, teachers, anyone keeping a room quiet). This is
  the simpler path. The listing and screenshots must then not look as if the
  app is made for children.
- [ ] **Children are part of the target group.** Mia, stars and a shop point
  this way. Google's
  [Families policy](https://support.google.com/googleplay/android-developer/answer/9893335)
  then applies: stricter review, extra declarations and teacher-approved
  rules. Raumfreund has no ads or data collection, which helps, but expect
  more work and a longer review.

Write the decision into `docs/plan.md` (or tell an agent to).

## Step 1: Create the upload key (🧑, 30 min)

Without this key no production release can be built. Follow
[`releasing.md` → "Creating the upload key"](releasing.md#creating-the-upload-key-owner-once):

- [ ] Create `~/raumfreund-upload.jks` with `keytool` (command in
  `releasing.md`). Use a password manager for the password.
- [ ] Back up the `.jks` file and the password in **two** separate safe places,
  for example the password manager and an offline USB stick.
- [ ] Store the four secrets in the GitHub `release` environment with the
  `gh secret set … --env release` commands from `releasing.md`.
- [ ] Check them: `gh secret list --env release` shows
  `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`,
  `ANDROID_KEY_ALIAS` and `ANDROID_KEY_PASSWORD`.
- [ ] Note the key's SHA-256 fingerprint
  (`keytool -list -v -keystore ~/raumfreund-upload.jks -alias upload`).

Never commit the keystore. `*.jks` and `android/key.properties` are git-ignored.

## Step 2: First production build (🤖 + 🧑, 1 h)

The Release workflow has never run with real secrets, so test it before Play
depends on it.

- [ ] 🤖 Bump the version on `main`, update the changelog and run
  `./localPipeline.sh` (see `releasing.md`, "Production release").
- [ ] 🧑 Create and push the tag: `git tag -s vX.Y.Z -m "Raumfreund X.Y.Z"`
  and `git push origin vX.Y.Z`. The tag must match the version in
  `pubspec.yaml`.
- [ ] 🧑 Approve the `release` environment deployment in GitHub Actions if
  GitHub asks for it.
- [ ] Check that the GitHub release contains the signed APK, the `.aab`,
  checksums and the SBOM.
- [ ] Install the signed APK on a real phone and start a measurement once.
  An installed debug release must be uninstalled first, because it has a
  different certificate.

If the workflow fails, hand the run link to an agent. Do not upload a
debug-signed build anywhere as a substitute.

## Step 3: Create the developer account (🧑, 1 h plus waiting)

- [ ] Open [Play Console](https://play.google.com/console/signup) and sign
  up, ideally with a dedicated Google account for the app.
- [ ] Choose **personal** (you as a person) or **organization** (needs a
  D-U-N-S number, which takes days to weeks).
- [ ] Pay the one-time registration fee (US$25).
- [ ] Complete identity verification (official ID, sometimes a payment
  profile or address check). This can take a few days.
- [ ] Verify the contact email and phone number. The developer email is shown
  publicly in the store listing.

## Step 4: Create the app in Play Console (🧑, 30 min)

- [ ] **Create app**: name "Raumfreund", default language German, type
  **App**, **Free**. Confirm the declarations. A free app can never become
  paid later.
- [ ] **App signing**: accept **Play App Signing**. Google keeps the key that
  signs what users install; your key from step 1 becomes only the upload key.
  If you lose it, Google can reset it.
- [ ] Note the package name `it.marcelpetrick.raumfreund`. It is fixed
  forever with the first upload.

## Step 5: Store listing (🤖 drafts, 🧑 reviews and pastes, 2 h)

Main store listing, at least German and English (Croatian and Simplified
Chinese are optional, since the app already speaks them):

- [ ] 🤖 App name (max. 30 characters), short description (max. 80) and full
  description (max. 4000) in German and English. No claims of being a
  calibrated sound-level meter.
- [ ] 🤖 App icon, 512 × 512 PNG, derived from `ic_launcher`.
- [ ] 🤖 Feature graphic, 1024 × 500 PNG or JPEG.
- [ ] 🤖 Phone screenshots (2 to 8) and 7" and 10" tablet screenshots from
  `tool/render_screenshots.sh`.
- [ ] 🧑 Category (likely **Tools** or **Education**), contact email
  `mail@marcelpetrick.it`, optional website (the GitHub repository).
- [ ] 🧑 Paste and upload everything, then save.

## Step 6: App content and policy forms (🧑 with 🤖 drafts, 2 h)

In Play Console under **Policy and programs → App content**:

- [ ] 🤖 **Privacy policy**: publish the content of
  [`privacy.md`](privacy.md) at a public URL, for example with GitHub Pages.
  🧑 Enter the URL. It is mandatory because the app uses the microphone.
- [ ] **Ads**: "No, my app does not contain ads".
- [ ] **App access**: "All functionality is available without special
  access" (no login).
- [ ] **Content rating**: fill in the IARC questionnaire (category Utility or
  Productivity; no violence, no user-generated content, no sharing). The
  shop uses only earned stars, no real money.
- [ ] **Target audience and content**: enter the age groups from step 0.
- [ ] **Data safety**: Raumfreund collects and shares **no** data. Audio is
  processed only on the device, in memory, and never leaves it, which Google
  does not count as collection. Answer "No" to collection and sharing, and
  state that there is no data transfer. 🤖 can draft the answers against the
  current form.
- [ ] **Government apps**, **Financial features**, **Health**, **News**:
  answer "No" or "not applicable".
- [ ] Check the **Sensitive permissions** page if it appears. `RECORD_AUDIO`
  needs no special declaration, but the listing must make the microphone
  use clear.

## Step 7: Closed test (🧑, at least 14 days)

New personal developer accounts may publish to production only after a
closed test. Last known rule: at least **12 testers** opted in for
**14 days in a row**. Check the current numbers on the Play Console
dashboard.

- [ ] **Testing → Closed testing → Create track**, then upload the `.aab`
  from the GitHub release of step 2.
- [ ] Create a tester list with at least 12, better 15, Google accounts
  (friends, family, colleagues) and share the opt-in link.
- [ ] Make sure every tester actually opts in **and** installs, and keeps
  the app for the whole 14 days. Invite a few extra in case someone drops
  out.
- [ ] Use the time for the open real-device checks from
  [`testing.md`](testing.md): microphone levels, alarm vibration, background
  pause and wake-up, TalkBack, large text and reduced motion.
- [ ] Collect feedback. Fix bugs with new `vX.Y.Z` tags and upload each new
  `.aab` to the same track. The `versionCode` rises with every commit
  anyway.

## Step 8: Apply for production access (🧑, 30 min plus review)

- [ ] On the dashboard, **Apply for production**. Google asks how the test
  went, what the testers said and what changed.
- [ ] Wait for approval, usually a few days.

## Step 9: Production release (🧑, 30 min plus review)

- [ ] **Production → Create new release**, take the tested `.aab` and paste
  release notes from `CHANGELOG.md`.
- [ ] Choose countries (all, or start with DACH and Croatia).
- [ ] Optional: a staged rollout, for example 20 % first.
- [ ] **Send for review**. The first review can take up to a week.
- [ ] Once published: put the Play link in `README.md` and record the state
  in `docs/plan.md` (🤖).

## Afterwards

- Keep the GitHub debug releases as a separate channel. Play users cannot
  update from them and vice versa, because the certificates differ.
- Google raises the required target API every year. Keep the dependency
  refreshes going, or Play will block updates.
- Answer policy emails from Google promptly; ignored warnings can get the app
  removed.

## Rough time budget

| Step | Your time | Waiting |
| --- | --- | --- |
| 0–2 Decision, key, first build | ~2 h | – |
| 3 Account and verification | ~1 h | days |
| 4–6 App, listing and forms | ~4 h | – |
| 7 Closed test | ~2 h | 14 days or more |
| 8–9 Production access and release | ~1 h | days to a week |

Expect roughly three to four weeks from start to the app being live, most of
it waiting.
