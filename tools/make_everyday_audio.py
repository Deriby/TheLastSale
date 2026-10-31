"""Original mono shop/road sounds for the spatial everyday-horror mix."""
from pathlib import Path
import math,subprocess,tempfile,wave
import numpy as np
ROOT=Path(__file__).resolve().parent.parent
RATE=22050

def main():
    folder=ROOT/'assets/audio/everyday';folder.mkdir(parents=True,exist_ok=True)
    rng=np.random.default_rng(280)
    def noise(count,cutoff):
        spectrum=np.fft.rfft(rng.normal(size=count));frequencies=np.fft.rfftfreq(count,1/RATE)
        result=np.fft.irfft(spectrum/(1+(frequencies/cutoff)**4),n=count)
        return result/max(1e-6,float(np.max(np.abs(result))))
    sounds={}
    t=np.arange(8*RATE)/RATE
    sounds['compressor']=(.10*np.sin(math.tau*55*t)+.035*np.sin(math.tau*110*t)+.025*noise(len(t),420))*(.90+.10*np.cos(math.tau*.5*t))
    sounds['car_idle']=(.08*np.sin(math.tau*32*t)+.055*np.sin(math.tau*64*t)+.025*np.sin(math.tau*96*t)+.018*noise(len(t),200))*(.87+.13*np.sin(math.tau*.25*t))
    t=np.arange(round(1.8*RATE))/RATE;chime=np.zeros_like(t)
    for onset,frequency in [(0.,1470),(.23,1175)]:
        age=np.maximum(t-onset,0);env=np.where(t>=onset,(1-np.exp(-age*600))*np.exp(-age*4.8),0)
        chime+=env*(.17*np.sin(math.tau*frequency*age)+.035*np.sin(math.tau*frequency*2.76*age))
    sounds['entry_chime']=chime
    t=np.arange(round(2.7*RATE))/RATE;steps=np.zeros_like(t);texture=noise(len(t),850)
    for onset in [.20,.87,1.56,2.18]:
        age=np.maximum(t-onset,0);env=np.where(t>=onset,(1-np.exp(-age*700))*np.exp(-age*27),0)
        steps+=env*(.17*np.sin(math.tau*105*age)+.11*texture)
    sounds['stock_steps']=steps
    with tempfile.TemporaryDirectory(prefix='thelastsale-daily-audio-') as temp:
        for name,samples in sounds.items():
            samples=np.clip(samples,-.85,.85)
            if name in ['compressor','car_idle']:
                # Periodic tones/noise; gently close the small last-sample boundary.
                width=round(.012*RATE);delta=samples[-1]-samples[0];samples[-width:]-=delta*np.linspace(0,1,width)
            source=Path(temp)/(name+'.wav')
            with wave.open(str(source),'wb') as out:
                out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE);out.writeframes((samples*32767).astype('<i2').tobytes())
            target=folder/(name+'.ogg');subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-c:a','libvorbis','-q:a','1',str(target)],check=True)
            print(name,target.stat().st_size)
    (folder/'README.txt').write_text('Original synthesized spatial sounds for A Ultima Venda.\nCompressor, idling engine, entry bell and stock-room footsteps.\nCreated with tools/make_everyday_audio.py. No recordings or audio from other games.\n')
if __name__=='__main__':main()
