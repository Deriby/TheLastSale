from PIL import Image,ImageDraw
from pathlib import Path
import random,math,wave,struct
random.seed(19);root=Path(__file__).resolve().parents[1]
for name,base in [('plaster',(174,169,147)),('asphalt',(49,51,53)),('concrete',(113,111,100)),('tile',(181,179,158)),('metal',(85,90,88)),('cardboard',(145,106,63))]:
 im=Image.new('RGB',(128,128));pix=im.load()
 for y in range(128):
  for x in range(128):
   v=random.randint(-9,9);pix[x,y]=tuple(max(0,min(255,c+v)) for c in base)
 d=ImageDraw.Draw(im)
 if name=='tile':d.line((0,0,127,0),fill=(91,94,88),width=2);d.line((0,0,0,127),fill=(91,94,88),width=2)
 if name=='metal':
  for y in range(0,128,8):d.line((0,y,127,y),fill=(49,55,53),width=2)
 if name=='cardboard':d.rectangle((55,0,73,127),fill=(173,139,87));d.text((12,35),'BEBIDAS',fill=(55,43,29));d.text((12,58),'FRANCA',fill=(55,43,29));d.text((12,90),'12 x 600',fill=(55,43,29))
 im.save(root/'assets/textures'/f'{name}.png')
# Original synthesized audio, no third-party recordings.
sr=22050
for name,seconds in [('hum',3),('night',5),('step',.16),('crate',.35),('register',.4),('knock',.7),('radio',8)]:
 samples=[]
 for i in range(int(sr*seconds)):
  t=i/sr;n=random.uniform(-1,1)
  if name=='hum':v=(math.sin(2*math.pi*60*t)+.25*math.sin(2*math.pi*120*t))*.065
  elif name=='night':v=(n*.08+math.sin(2*math.pi*2700*t)*max(0,math.sin(t*19))**15*.12)*.5
  elif name=='step':v=n*math.exp(-t*28)*.35
  elif name=='crate':v=(n*.25+math.sin(t*190)*.3)*math.exp(-t*14)
  elif name=='knock':v=(math.sin(t*400)*.45+n*.12)*math.exp(-(t%0.22)*33)*(1 if t<.5 else 0)
  elif name=='register':v=math.sin(2*math.pi*(880 if t<.15 else 1320)*t)*math.exp(-t*7)*.2
  else:
   notes=[220,261.63,329.63,293.66,196,246.94,293.66,261.63];f=notes[int(t*2)%8]
   v=(math.sin(2*math.pi*f*t)+.25*math.sin(2*math.pi*f*2*t))*.035*math.exp(-(t%.5)*5)
  samples.append(struct.pack('<h',int(max(-1,min(1,v))*32767)))
 with wave.open(str(root/'assets/audio'/f'{name}.wav'),'wb') as w:w.setparams((1,2,sr,0,'NONE','not compressed'));w.writeframes(b''.join(samples))
