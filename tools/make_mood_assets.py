"""Deterministic original surface art, night panorama and quiet environmental audio.
Python + Pillow + NumPy. No photographic or third-party game assets.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import random, math, wave

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/textures/mood'; OUT.mkdir(parents=True,exist_ok=True)
rng=np.random.default_rng(606558)
def field(width,height):
    value=np.zeros((height,width),np.float32)
    for size,weight in [(4,.45),(8,.26),(16,.16),(32,.08),(64,.05)]:
        source=rng.integers(0,256,(size,size),dtype=np.uint8)
        # Wrap the edge so the large features tile cleanly.
        source=np.pad(source,((0,1),(0,1)),mode='wrap')
        layer=Image.fromarray(source).resize((width+width//size,height+height//size),Image.Resampling.BICUBIC)
        value+=np.asarray(layer,dtype=np.float32)[:height,:width]/255*weight
    return value
def surface(name,base,variation,grain):
    cloud=field(512,512)-.5
    noise=rng.normal(0,grain,(512,512))
    rgb=np.stack([c+cloud*variation+noise for c in base],axis=-1)
    return Image.fromarray(np.uint8(np.clip(rgb,0,255)))
im=surface('asphalt',(77,79,79),24,3.8);d=ImageDraw.Draw(im)
detail=random.Random(606)
for i in range(4600):
    x,y=detail.randrange(512),detail.randrange(512);c=detail.randrange(64,101)
    d.point((x,y),fill=(c,c+1,c))
im.save(OUT/'asphalt.png')
surface('plaster',(190,190,180),21,1.4).save(OUT/'plaster.png')
im=surface('paving',(161,155,139),29,2.1);d=ImageDraw.Draw(im)
for i in range(45):
    x,y=detail.randrange(512),detail.randrange(512)
    d.line([(x,y),(x+detail.randrange(-3,4),y+detail.randrange(3,13))],fill=(135,130,115),width=1)
im.save(OUT/'paving.png')
im=surface('tile',(204,204,192),7,1.2);d=ImageDraw.Draw(im)
d.line((0,0,511,0),fill=(143,148,138),width=3);d.line((0,0,0,511),fill=(143,148,138),width=3)
d.line((4,4,511,4),fill=(216,217,205));d.line((4,4,4,511),fill=(216,217,205))
im.save(OUT/'tile.png')
im=Image.new('RGB',(256,256));p=im.load()
for y in range(256):
    for x in range(256):
        fold=(math.sin(x*.18)+math.sin(x*.47)*.3)*8
        light=1-abs(y-125)/440
        gap=.22 if abs(x-128)<12+int(y*.035) else 1.0
        p[x,y]=tuple(int(max(0,min(255,(c+fold)*light*gap))) for c in (155,121,77))
im.save(OUT/'curtain.png')
# Transparent dirt at the foot of a wall, without hard rectangular decal edges.
im=Image.new('RGBA',(512,256));p=im.load();weather=field(512,256)
for y in range(256):
    for x in range(512):
        edge=max(0,min(1,x/32,(511-x)/32))
        height=max(0,(y/255-weather[y,x]*.68))
        p[x,y]=(76,75,59,int(height**1.3*edge*75))
im.save(OUT/'wall_base.png')
im=Image.new('RGBA',(128,128));p=im.load()
for y in range(128):
    for x in range(128):
        distance=math.hypot((x-63.5)/63.5,(y-63.5)/63.5)
        p[x,y]=(255,232,192,int(max(0,1-distance)**3*95))
im.save(OUT/'lamp_halo.png')
# Irregular cutout leaf clusters replace solid rounded foliage.
im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
for i in range(210):
    angle=detail.random()*math.tau;radius=math.sqrt(detail.random())*107
    x=128+math.sin(angle)*radius;y=128+math.cos(angle)*radius*.83
    length=detail.randrange(5,14);width=detail.randrange(2,5);tilt=detail.random()*math.tau
    along=(math.cos(tilt)*length,math.sin(tilt)*length);across=(-math.sin(tilt)*width,math.cos(tilt)*width)
    col=detail.choice([(98,119,70,255),(122,139,80,255),(76,103,61,255),(148,155,92,255)])
    d.polygon([(x-along[0],y-along[1]),(x+across[0],y+across[1]),(x+along[0],y+along[1]),(x-across[0],y-across[1])],fill=col)
im.save(OUT/'leaves.png')
# Panorama: dark zenith, light-polluted horizon and broad low-contrast cloud cover.
w,h=1024,512;cloud=field(w,h);im=Image.new('RGB',(w,h));p=im.load()
for y in range(h):
    horizon=math.exp(-((y/h-.5)/.17)**2)
    for x in range(w):
        haze=(cloud[y,x]-.5)*6*horizon
        p[x,y]=tuple(int(max(0,c+horizon*v+haze)) for c,v in [(6,21),(10,25),(16,25)])
im.save(OUT/'night_sky.png')

rate=22050;audio=ROOT/'assets/audio'
for name,seconds in [('neighborhood_air',24),('pole_ballast',12),('step_tile',.18),('step_asphalt',.22)]:
    n=int(rate*seconds);noise=rng.uniform(-1,1,n);t=np.arange(n)/rate
    smooth=np.convolve(noise,np.ones(47)/47,mode='same')
    if name=='neighborhood_air':
        envelope=.65+.16*np.sin(t*.43)+.12*np.sin(t*.17+1)
        samples=(smooth*.18+noise*.007)*envelope
        # Long, quiet airflow; the first/last second meet with matching amplitude.
        samples*=np.minimum(1,np.minimum(t,seconds-t))
    elif name=='pole_ballast':
        samples=(np.sin(t*math.tau*120)*.012+noise*.003)*(.85+.10*np.sin(t*.8))
        samples*=np.minimum(1,np.minimum(t,seconds-t)*2)
    elif name=='step_tile':
        samples=(noise*.16*np.exp(-t*48)+np.sin(t*math.tau*180)*.13*np.exp(-t*36))
    else:
        samples=(smooth*.65+noise*.09)*np.exp(-t*25)
    pcm=np.int16(np.clip(samples,-1,1)*32767)
    with wave.open(str(audio/(name+'.wav')),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(pcm.tobytes())
for metadata in OUT.glob('*.png.import'):
    metadata.write_text(metadata.read_text().replace('mipmaps/generate=false','mipmaps/generate=true'))
print('Mood art:',len(list(OUT.glob('*.png'))),'| original ambient/footstep sounds: 4')
