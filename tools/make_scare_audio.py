"""Original mono Foley for the Friday scares; numpy and ffmpeg required to rebuild."""
from pathlib import Path
import math, subprocess, tempfile, wave
import numpy as np
ROOT=Path(__file__).resolve().parent.parent
RATE=22050
def main():
 rng=np.random.default_rng(300)
 def noise(t,cutoff):
  raw=rng.normal(size=len(t));freq=np.fft.rfftfreq(len(t),1/RATE)
  raw=np.fft.irfft(np.fft.rfft(raw)/(1+(freq/cutoff)**4),n=len(t))
  return raw/max(.001,float(abs(raw).max()))
 sounds={}
 t=np.arange(3*RATE)/RATE
 sounds['stock_drag']=(.21*noise(t,950)+.065*np.sin(math.tau*(121*t+9*np.sin(math.tau*.66*t))))*(.45+.55*np.sin(math.tau*t/3)**2)
 t=np.arange(round(1.75*RATE))/RATE
 sounds['handle_rattle']=np.zeros_like(t)
 for onset in [0,.19,.44,.73,1.07,1.31]:
  age=np.maximum(t-onset,0);env=np.where(t>=onset,(1-np.exp(-age*1100))*np.exp(-age*29),0)
  sounds['handle_rattle']+=env*(.23*noise(t,4500)+.18*np.sin(math.tau*1470*age))
 t=np.arange(round(.85*RATE))/RATE
 sounds['glass_tap']=np.zeros_like(t)
 for onset in [0,.16]:
  age=np.maximum(t-onset,0);env=np.where(t>=onset,(1-np.exp(-age*1800))*np.exp(-age*23),0)
  sounds['glass_tap']+=env*(.25*np.sin(math.tau*790*age)+.15*np.sin(math.tau*1860*age)+.09*noise(t,6000))
 t=np.arange(round(1.25*RATE))/RATE;env=(1-np.exp(-t*1400))*np.exp(-t*9)
 sounds['door_slam']=env*(.34*noise(t,1400)+.22*np.sin(math.tau*69*t)+.13*np.sin(math.tau*147*t))
 folder=ROOT/'assets/audio/scares';folder.mkdir(exist_ok=True)
 with tempfile.TemporaryDirectory(prefix='thelastsale-scare-foley-') as temp:
  for name,data in sounds.items():
   data=np.clip(data,-.8,.8);ramp=min(round(.006*RATE),len(data)//4);data[:ramp]*=np.linspace(0,1,ramp);data[-ramp:]*=np.linspace(1,0,ramp)
   source=Path(temp)/(name+'.wav')
   with wave.open(str(source),'wb') as out:out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE);out.writeframes((data*32767).astype('<i2').tobytes())
   target=folder/(name+'.ogg');subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-c:a','libvorbis','-q:a','1',str(target)],check=True);print(name,target.stat().st_size)
 (folder/'README.txt').write_text('Original synthesized Foley for A Ultima Venda: stock drag, handle rattle, glass taps and a steel door slam. Created with tools/make_scare_audio.py. No recordings from other games.\n')
if __name__=='__main__':main()
