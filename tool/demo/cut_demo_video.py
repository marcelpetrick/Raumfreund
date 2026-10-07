#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Marcel Petrick <mail@marcelpetrick.it>
"""Cut the two 4:5 social-media candidates from a recorded demo take.

Purpose: turn the take of tool/demo/record_demo.sh into two videos of
1080x1350 pixels, 30 fps, at most 29.9 s, with a silent audio track:

  A "Story"  the whole phone on a brand gradient, caption above,
             chronological.
  B "Hook"   opens on the loud moment, native-size crop of the action under
             a bold caption band.

Segments are offsets from the scene marks in events.log, so a new take cuts
correctly even when its timing drifts a little. Captions use the Roboto
fonts bundled with the pinned Flutter SDK.

Usage:      cut_demo_video.py <take.mp4> <events.log> <output-dir>
Exit codes: 0 written, 1 ffmpeg/ImageMagick failed, 2 usage or missing input.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FONTS = ROOT / ".toolchain/flutter/bin/cache/artifacts/material_fonts"
BOLD, MEDIUM = FONTS / "Roboto-Black.ttf", FONTS / "Roboto-Medium.ttf"
W, H, FPS, MAX_SECONDS = 1080, 1350, 30, 29.9
BG_TOP, BG_BOTTOM = "#120b2b", "#3a1a63"
WHITE, LAVENDER, MINT = "white", "#c9b8ff", "#3dffa6"
PHONE_W, PHONE_H, BAND = 540, 1200, 210
END_SECONDS = 2.4


@dataclass(frozen=True)
class Style:
    """Font, size, color and vertical position of one caption line."""

    font: Path
    size: int
    color: str
    y: str


@dataclass(frozen=True)
class Segment:
    """One scene: offsets from an event mark, speed-up, captions, crop."""

    mark: str
    start: float
    end: float
    speed: float
    headline: str
    subline: str
    crop_y: int


SEGMENTS = {
    "idle": Segment("idle", 0.4, 2.4, 1.0, "Raumfreund", "Die Lärmampel mit Katze", 250),
    "limits": Segment(
        "delay", 2.1, 12.8, 4.5, "Einstellbar", "Grenzwerte und Alarm-Wartezeit", 250
    ),
    "quick": Segment(
        "quickstars", -0.4, 2.0, 1.2, "Stern-Testmodus", "Ein Stern alle 5 ruhigen Sekunden", 250
    ),
    "green": Segment("run1", 0.86, 8.56, 2.0, "Leise = grün", "Ruhige Minuten bringen Sterne", 480),
    "loud": Segment(
        "run1", 13.06, 26.46, 3.0, "Zu laut?", "Mia erschrickt \u2013 und versteckt sich", 480
    ),
    "back": Segment("run1", 29.46, 33.86, 2.0, "Wieder ruhig", "Mia kommt zurück", 480),
    "shop": Segment(
        "shop", 0.12, 20.72, 4.0, "Sternenladen", "Sterne gegen Schleife und Partyhut", 250
    ),
    "run2": Segment(
        "run2", 0.13, 6.93, 2.5, "Mia mit Schleife und Partyhut", "Und weiter geht's", 480
    ),
    "about": Segment(
        "about", 0.12, 4.72, 2.2, "Offline und Open Source", "Kein Ton wird gespeichert", 250
    ),
}
ORDER_A = ["idle", "limits", "quick", "green", "loud", "back", "shop", "run2", "about"]
ORDER_B = ["loud", "back", "limits", "quick", "green", "shop", "run2", "about"]
HOOK = ("Zu laut im Klassenzimmer?", "Mia merkt es zuerst.")
END_LINES = (
    ("Raumfreund", Style(BOLD, 92, WHITE, "(h/2)-190"), 0.0),
    ("Die freundliche Lärmampel für Klassenräume", Style(MEDIUM, 38, LAVENDER, "(h/2)-70"), 0.15),
    ("Android · offline · keine Werbung · GPL-3.0", Style(MEDIUM, 34, MINT, "(h/2)+10"), 0.3),
    ("github.com/marcelpetrick/Raumfreund", Style(BOLD, 42, WHITE, "(h/2)+120"), 0.45),
)


class Cutter:
    """Renders the parts and both candidates into one work directory."""

    def __init__(self, take: Path, marks: dict[str, float], out: Path) -> None:
        self.take, self.marks, self.out = take, marks, out
        self.work = out / "work"
        self.ffmpeg = _tool("ffmpeg")
        self.magick = _tool("magick")
        self._texts = 0

    def run(self, cmd: list[str]) -> None:
        # Fixed tool paths and generated arguments only; nothing comes from
        # untrusted input.
        subprocess.run(cmd, check=True)  # noqa: S603

    def text(self, text: str, style: Style, spec: tuple[float, float]) -> str:
        """drawtext filter that fades in after spec[1] and out at spec[0]."""
        self._texts += 1
        path = self.work / f"text{self._texts}.txt"
        path.write_text(text, encoding="utf-8")
        duration, delay = spec
        alpha = (
            f"'if(lt(t,{delay}),0,if(lt(t,{delay}+0.25),(t-{delay})/0.25,"
            f"if(gt(t,{duration:.3f}-0.2),max(0,({duration:.3f}-t)/0.2),1)))'"
        )
        return (
            f"drawtext=fontfile='{_esc(style.font)}':textfile='{_esc(path)}':fontsize={style.size}"
            f":fontcolor={style.color}:x=(w-text_w)/2:y={style.y}:alpha={alpha}"
        )

    def assets(self) -> None:
        """Background gradient, rounded phone mask and its glow."""
        m, pw, ph, r = self.magick, PHONE_W, PHONE_H, 46
        self.run(
            [
                m,
                "-size",
                f"{W}x{H}",
                f"gradient:{BG_TOP}-{BG_BOTTOM}",
                "(",
                "-size",
                f"{W}x{H}",
                "radial-gradient:#6b3fd455-none",
                ")",
                "-compose",
                "over",
                "-composite",
                str(self.work / "bg.png"),
            ]
        )
        self.run(
            [
                m,
                "-size",
                f"{pw}x{ph}",
                "xc:black",
                "-fill",
                "white",
                "-draw",
                f"roundrectangle 0,0 {pw - 1},{ph - 1} {r},{r}",
                str(self.work / "mask.png"),
            ]
        )
        self.run(
            [
                m,
                "-size",
                f"{pw + 60}x{ph + 60}",
                "xc:none",
                "-fill",
                "#8f6bff",
                "-draw",
                f"roundrectangle 30,30 {pw + 29},{ph + 29} {r},{r}",
                "-blur",
                "0x18",
                str(self.work / "glow.png"),
            ]
        )

    def window(self, seg: Segment) -> tuple[float, float, float]:
        """Absolute source start, end and the resulting clip duration."""
        base = self.marks[seg.mark]
        return base + seg.start, base + seg.end, (seg.end - seg.start) / seg.speed

    def clip_story(self, key: str) -> Path:
        seg = SEGMENTS[key]
        start, end, dur = self.window(seg)
        px, py = (W - PHONE_W) // 2, H - PHONE_H - 20
        graph = (
            f"[0:v]setpts=(PTS-STARTPTS)/{seg.speed},fps={FPS},"
            f"scale={PHONE_W}:{PHONE_H}:flags=lanczos,format=yuva420p[s];[s][2:v]alphamerge[p];"
            f"[1:v]loop=-1:1,trim=duration={dur:.3f},fps={FPS}[bg];"
            f"[3:v]loop=-1:1,trim=duration={dur:.3f},fps={FPS}[g];"
            f"[bg][g]overlay={px - 30}:{py - 30}[bg2];[bg2][p]overlay={px}:{py},"
            + self.text(seg.headline, Style(BOLD, 50, WHITE, "26"), (dur, 0.0))
            + ","
            + self.text(seg.subline, Style(MEDIUM, 32, LAVENDER, "86"), (dur, 0.1))
            + ",format=yuv420p[v]"
        )
        assets = [self.work / name for name in ("bg.png", "mask.png", "glow.png")]
        return self.encode(f"a_{key}", (start, end), graph, assets)

    def clip_hook(self, key: str, *, first: bool) -> Path:
        seg = SEGMENTS[key]
        start, end, dur = self.window(seg)
        headline, subline = HOOK if first else (seg.headline, seg.subline)
        graph = (
            f"[0:v]setpts=(PTS-STARTPTS)/{seg.speed},fps={FPS},"
            f"crop=1080:{H - BAND}:0:{seg.crop_y}[s];"
            f"[1:v]loop=-1:1,trim=duration={dur:.3f},fps={FPS},crop={W}:{BAND}:0:0[t];"
            f"[t][s]vstack,"
            + self.text(headline, Style(BOLD, 60, WHITE, "34"), (dur, 0.0))
            + ","
            + self.text(subline, Style(MEDIUM, 38, MINT, "116"), (dur, 0.1))
            + ",format=yuv420p[v]"
        )
        return self.encode(f"b_{key}", (start, end), graph, [self.work / "bg.png"])

    def encode(self, name: str, window: tuple[float, float], graph: str, extra: list[Path]) -> Path:
        out = self.work / f"{name}.mp4"
        cmd = [
            self.ffmpeg,
            "-v",
            "error",
            "-y",
            "-ss",
            f"{window[0]:.3f}",
            "-to",
            f"{window[1]:.3f}",
            "-i",
            str(self.take),
        ]
        for path in extra:
            cmd += ["-i", str(path)]
        cmd += [
            "-filter_complex",
            graph,
            "-map",
            "[v]",
            "-an",
            "-c:v",
            "libx264",
            "-crf",
            "16",
            "-pix_fmt",
            "yuv420p",
            "-r",
            str(FPS),
            str(out),
        ]
        self.run(cmd)
        return out

    def end_card(self) -> Path:
        out = self.work / "end.mp4"
        texts = ",".join(
            self.text(text, style, (END_SECONDS, delay)) for text, style, delay in END_LINES
        )
        self.run(
            [
                self.ffmpeg,
                "-v",
                "error",
                "-y",
                "-loop",
                "1",
                "-t",
                f"{END_SECONDS}",
                "-i",
                str(self.work / "bg.png"),
                "-vf",
                f"fps={FPS},{texts},format=yuv420p",
                "-c:v",
                "libx264",
                "-crf",
                "16",
                "-pix_fmt",
                "yuv420p",
                str(out),
            ]
        )
        return out

    def concat(self, parts: list[Path], name: str) -> Path:
        listing = self.work / f"{name}.txt"
        listing.write_text("".join(f"file '{p}'\n" for p in parts), encoding="utf-8")
        out = self.out / f"{name}.mp4"
        self.run(
            [
                self.ffmpeg,
                "-v",
                "error",
                "-y",
                "-f",
                "concat",
                "-safe",
                "0",
                "-i",
                str(listing),
                "-f",
                "lavfi",
                "-i",
                "anullsrc=r=48000:cl=stereo",
                "-shortest",
                "-t",
                f"{MAX_SECONDS}",
                "-c:v",
                "copy",
                "-c:a",
                "aac",
                "-b:a",
                "128k",
                "-movflags",
                "+faststart",
                str(out),
            ]
        )
        return out

    def render(self) -> list[Path]:
        self.work.mkdir(parents=True, exist_ok=True)
        self.assets()
        end = self.end_card()
        story = [self.clip_story(key) for key in ORDER_A]
        hook = [self.clip_hook(key, first=i == 0) for i, key in enumerate(ORDER_B)]
        return [
            self.concat([*story, end], "raumfreund_A_story_4x5"),
            self.concat([*hook, end], "raumfreund_B_hook_4x5"),
        ]


def _esc(path: Path) -> str:
    return str(path).replace(":", r"\:")


def _tool(name: str) -> str:
    path = shutil.which(name)
    if path is None:
        raise FileNotFoundError(f"{name} is not installed")
    return path


def read_marks(path: Path) -> dict[str, float]:
    """Parse events.log lines "<seconds> <scene>" into {scene: seconds}."""
    marks: dict[str, float] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        seconds, _, scene = line.strip().partition(" ")
        if scene:
            marks[scene] = float(seconds)
    return marks


def main(argv: list[str] | None = None) -> int:
    """Command line entry point; see the module docstring."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("take", type=Path)
    parser.add_argument("events", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args(argv)
    try:
        cutter = Cutter(args.take, read_marks(args.events), args.out)
        if not args.take.is_file():
            raise FileNotFoundError(args.take)
        outputs = cutter.render()
    except (OSError, KeyError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    except subprocess.CalledProcessError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    for output in outputs:
        print(output)
    return 0


if __name__ == "__main__":
    sys.exit(main())
