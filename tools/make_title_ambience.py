"""Synthesize original stereo menu ambience; no external recordings are used."""
from pathlib import Path
import math
import subprocess
import tempfile
from make_title_assets import audio, RATE

ROOT = Path(__file__).resolve().parent.parent


def hum(t, noise, low):
    edge = min(1, t / .08, (8 - t) / .08)
    base = (.11 * math.sin(math.tau * 60 * t)
            + .035 * math.sin(math.tau * 120.2 * t) + .05 * low) * edge
    return base, base * .83


def car(t, noise, low):
    progress = t / 7
    envelope = math.sin(math.pi * progress) ** 3
    engine = .16 * math.sin(math.tau * (220 * t - 65 * t * t / 7))
    road = .6 * low + .025 * noise
    value = (engine + road) * envelope
    return value * math.cos(progress * math.pi / 2), value * math.sin(progress * math.pi / 2)


def dog(t, noise, low):
    value = 0
    for onset in [.25, .72]:
        age = t - onset
        if 0 <= age < .45:
            envelope = math.sin(math.pi * min(1, age / .035)) if age < .0175 else math.exp(-(age - .0175) * 14)
            phase = math.tau * (185 * age - 65 * age * age)
            voice = math.sin(phase) + .48 * math.sin(phase * 2.03) + .22 * math.sin(phase * 5.1)
            value += (.17 * voice + .12 * low + .008 * noise) * envelope
    return value * .42, value * .85


def metal(t, noise, low):
    envelope = min(1, t / .012) * math.exp(-t * 3.4)
    value = sum(level * math.sin(math.tau * frequency * t) * math.exp(-t * decay)
                for frequency, level, decay in [(367, .10, .1), (641, .07, .3), (1067, .035, .9)])
    value = (value + .05 * low) * envelope
    return value * .9, value * .38


def stop(t, noise, low):
    click = .15 * noise * math.exp(-t * 100)
    motor = .09 * math.sin(math.tau * (520 * t - 590 * t * t))
    value = click + motor * math.sin(math.pi * min(1, t / .36)) ** 2 * math.exp(-t * 5)
    return value, value * .92


def main():
    output = ROOT / "assets/audio/title/ambient"
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="thelastsale-ambience-") as folder:
        for name, duration, sample in [("neon_hum", 8, hum), ("street_car", 7, car),
                                       ("distant_dog", 2, dog), ("metal_creak", 1.8, metal),
                                       ("tape_stop", .36, stop)]:
            source = Path(folder) / (name + ".wav")
            audio(source, duration, sample)
            target = output / (name + ".ogg")
            subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(source),
                            "-c:a", "libvorbis", "-q:a", "2", str(target)], check=True)
            print(target.relative_to(ROOT), target.stat().st_size)
    (output / "README.txt").write_text(
        "Original synthesized ambience for A Última Venda, created by tools/make_title_ambience.py.\n"
        "Stereo neon hum, passing traffic, distant dog, metal resonance and tape stop.\n"
        "No external recordings or audio from other games are used.\n")


if __name__ == "__main__":
    main()
