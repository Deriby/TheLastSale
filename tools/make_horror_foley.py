"""Build the original short scuff/impact accompanying Bryan's rear-stock prank."""
from pathlib import Path
import subprocess, tempfile, wave
import numpy as np
root=Path(__file__).resolve().parent.parent
rate=22050
t=np.arange(int(rate*.65))/rate
rng=np.random.default_rng(38)
noise=rng.normal(0,1,t.size)
noise=np.convolve(noise,np.ones(6)/6,mode='same')
env=(1-np.exp(-t*900))*np.exp(-t*16)
data=(noise*.31+np.sin(2*np.pi*(95*t-24*t*t))*.33)*env
for onset in [.13,.22]:
 age=np.maximum(t-onset,0)
 data+=np.where(t>=onset,np.exp(-age*40),0)*noise*.12
data=np.clip(data,-.8,.8)
with tempfile.TemporaryDirectory(prefix='bryan-foley-') as folder:
 source=Path(folder)/'pop.wav'
 with wave.open(str(source),'wb') as out:
  out.setnchannels(1);out.setsampwidth(2);out.setframerate(rate);out.writeframes((data*32767).astype('<i2').tobytes())
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-c:a','libvorbis','-q:a','2',str(root/'assets/audio/scares/bryan_pop.ogg')],check=True)
