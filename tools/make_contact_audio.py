"""Build the original contact-scare sting, using deterministic synthesis only."""
from pathlib import Path
import wave
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
RATE = 22050


def main():
    rng = np.random.default_rng(410)
    t = np.arange(round(.84 * RATE)) / RATE
    frequency = np.fft.rfftfreq(len(t), 1 / RATE)
    noise = np.fft.irfft(np.fft.rfft(rng.normal(size=len(t))) *
                        (frequency / (frequency + 180)) / (1 + (frequency / 4200) ** 4), n=len(t))
    noise /= max(.001, float(abs(noise).max()))
    envelope = (1 - np.exp(-t * 1500)) * np.exp(-t * 7.5)
    phase = 2 * np.pi * (46 * t + 23 * (1 - np.exp(-t * 11)))
    metal = sum(np.sin(phase * ratio) * weight for ratio, weight in
                [(1, .23), (2.91, .17), (5.17, .10), (7.43, .05)])
    data = (.66 * noise + metal) * envelope
    # Two decaying reflections, without looping or a sustained music layer.
    for delay, level in [(.047, .23), (.091, .13)]:
        n = round(delay * RATE)
        data[n:] += data[:-n].copy() * level
    data *= .82 / max(.001, float(abs(data).max()))
    data[-220:] *= np.linspace(1, 0, 220)
    with wave.open(str(ROOT / 'assets/audio/scares/contact_sting.wav'), 'wb') as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        out.writeframes((data * 32767).astype('<i2').tobytes())


if __name__ == '__main__':
    main()
