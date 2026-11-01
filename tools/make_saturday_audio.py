"""Rebuild the original cloth brush used behind Saturday's closed service door."""
from pathlib import Path
import subprocess
import tempfile
import wave
import numpy as np

ROOT = Path(__file__).resolve().parent.parent
RATE = 22050

def main():
    rng = np.random.default_rng(320)
    t = np.arange(round(.68 * RATE)) / RATE
    noise = rng.normal(size=len(t))
    freq = np.fft.rfftfreq(len(t), 1 / RATE)
    noise = np.fft.irfft(np.fft.rfft(noise) * (freq / (freq + 170)) / (1 + (freq / 1900) ** 4), n=len(t))
    noise /= max(.001, float(abs(noise).max()))
    envelope = np.sin(np.pi * t / .68) ** 2
    data = .31 * noise * envelope * (.62 + .38 * np.sin(2 * np.pi * 13 * t) ** 2)
    folder = ROOT / 'assets/audio/saturday'
    folder.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='thelastsale-cloth-') as temp:
        source = Path(temp) / 'cloth.wav'
        with wave.open(str(source), 'wb') as out:
            out.setnchannels(1)
            out.setsampwidth(2)
            out.setframerate(RATE)
            out.writeframes((data * 32767).astype('<i2').tobytes())
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(source), '-c:a', 'libvorbis', '-q:a', '1', str(folder / 'cloth_brush.ogg')], check=True)
    (folder / 'README.txt').write_text('Original synthesized cloth Foley for A Ultima Venda. Created with tools/make_saturday_audio.py; no third-party recording or game audio.\n')

if __name__ == '__main__':
    main()
