<!--
SPDX-License-Identifier: GPL-3.0-only
Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
-->

# LinkedIn notes – ten facts about Raumfreund

Material for a post next to the demo videos in this folder. Every number was
checked against the repository on 2026-10-07 (version `0.6.23+68`).

1. **The noise meter is a cat.** Mia is happy while the class is quiet, gets
   scared when it is too loud, and after the alarm she runs away and hides.
   She only comes back once the room is calm, and stays calm.
2. **One slammed door is not a loud class.** A zone counts only once it fills
   at least half of the last second, and red is left only when less than
   15 % of the last three seconds were loud. A single bang does not scare
   Mia; repeated shouting does.
3. **The app does not get upset about its own alarm.** The microphone hears
   the alarm tone, so readings are ignored while it plays. Otherwise the
   alarm would keep setting itself off.
4. **"Too quiet to be true" is an error.** Android's microphone privacy switch
   does not stop the recording, it feeds pure digital silence. No real
   classroom is that quiet, so instead of handing out stars for a muted
   microphone, Mia says "Keine Messwerte".
5. **Quiet pays, in stars.** Every quiet minute earns a star. In a 30-minute
   test run the app earned exactly 30. In the star shop the class can buy Mia
   a bow (3), a scarf (5), a party hat (8), a cushion (10) or a toy mouse (12).
   There is no money, no ads and no account.
6. **Nothing leaves the phone.** Audio is processed in memory and thrown away;
   it is never stored or sent. The app asks only for the microphone and
   vibration and has no internet permission at all. A privacy check in the
   build fails if network or audio-saving code ever sneaks in.
7. **Built with AI agents, kept honest by tests.** The app was built with AI
   coding agents under human direction. 523 Dart tests and 46 Kotlin tests
   cover it, at 98.76 % line coverage. A 21-step local
   pipeline, mirrored on GitHub Actions, must be green before every commit.
8. **The independent reviewer earned its keep.** A second AI agent, reviewing
   the first one's work, found the muted-microphone bug from fact 4 before
   any child could collect undeserved stars.
9. **Nobody felt the alarm buzz.** It was a single 300 ms vibration, and
   Android may tone down vibrations of unknown purpose, for example in silent
   mode. Now it vibrates in three pulses, marked as an alarm.
10. **The class in the demo video is a script.** With its software
    renderer, the emulator crashed whenever its virtual microphone started,
    so the video uses scripted noise: quiet work, rising chatter, shouting,
    calm again. Its real microphone,
    once it worked, delivered the quietest classroom ever: a steady 12 dB.

Facts: 5 days from the first commit (2026-10-03) to version 0.6.23, more
than 70 commits, GPL-3.0, Android 7 or newer.
Project: <https://github.com/marcelpetrick/Raumfreund>
