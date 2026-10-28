"""Original low-resolution surface/sign art from the supplied Street View references.
No photographic pixels are included in game textures. Python + Pillow.
"""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import math,random
OUT=Path(__file__).resolve().parents[1]/'assets/textures/street';OUT.mkdir(parents=True,exist_ok=True)
R=random.Random(558)
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf'
def font(size):return ImageFont.truetype(FONT,size)
def save(im,name):im.save(OUT/(name+'.png'))
for name,base in [('asphalt',(75,79,76)),('sidewalk',(158,151,130)),('render',(167,169,164)),('cream',(192,187,161)),('stained',(148,143,122)),('terracotta',(146,76,47)),('gate',(216,211,188))]:
 im=Image.new('RGB',(256,256));p=im.load()
 for y in range(256):
  for x in range(256):
   cloud=0 if name=='asphalt' else math.sin(x*.023)*math.sin(y*.041)*5+math.sin(x*.081+y*.019)*3
   noise=R.randrange(-9,10) if name=='asphalt' else R.randrange(-4,5)
   p[x,y]=tuple(max(0,min(255,int(c+noise+cloud))) for c in base)
 d=ImageDraw.Draw(im)
 if name in ['sidewalk','stained']:
  for i in range(95):
   x,y=R.randrange(256),R.randrange(256);radius=R.randrange(1,10)
   d.ellipse((x,y,x+radius*2,y+radius),fill=tuple(max(0,c-R.randrange(8,38)) for c in base))
 if name=='stained':
  for x in range(256):
   length=R.randrange(4,45)+int((math.sin(x*.14)+1)*18)
   d.line((x,0,x,length),fill=(78+R.randrange(18),80+R.randrange(18),65+R.randrange(15)),width=1)
 if name=='gate':
  for x in range(0,256,16):
   d.line((x,0,x,255),fill=(157,164,143),width=1);d.line((x+3,0,x+3,255),fill=(231,227,205))
  for i in range(20):
   x,y=R.randrange(256),R.randrange(256);d.line((x,y,x+R.randrange(-2,3),y+R.randrange(2,12)),fill=(151,122,87),width=1)
 if name=='terracotta':
  for y in range(0,256,32):
   for x in range(-16,256,24):
    xx=x+(12 if y%64 else 0);d.rectangle((xx,y,xx+22,y+29),outline=(93,48,32));d.line((xx+3,y+2,xx+3,y+27),fill=(183,112,70),width=2)
 save(im,name)
im=Image.new('RGB',(256,256),(29,35,37));d=ImageDraw.Draw(im)
for y in range(0,256,4):
 d.line((0,y,255,y),fill=(64,71,72));d.line((0,y+1,255,y+1),fill=(22,29,31))
for i in range(220):
 x,y=R.randrange(256),R.randrange(256);d.line((x,y,x+R.randrange(1,13),y),fill=(79,82,79))
save(im,'shutter')
# Transparent JA mural: tall lettering, red laurel and the observed banner.
im=Image.new('RGBA',(768,640));d=ImageDraw.Draw(im)
for side in [-1,1]:
 for i in range(20):
  t=math.radians(-78+i*7.3);x=384+side*(145+88*math.cos(t));y=328+238*math.sin(t)
  leaf=Image.new('RGBA',(70,36));ld=ImageDraw.Draw(leaf);ld.ellipse((2,4,67,31),fill=(190,108+int(i*.9),96,255));leaf=leaf.rotate(side*(i*4-35),resample=Image.Resampling.BICUBIC,expand=True)
  im.alpha_composite(leaf,(round(x-leaf.width/2),round(y-leaf.height/2)))
d=ImageDraw.Draw(im)
for side in [-1,1]:
 # Small cattle silhouettes above the banner, interpreted from the low-resolution mural.
 x=384+side*95;d.ellipse((x-65,43,x+58,113),fill=(157,79,70));d.polygon([(x-56,68),(x-82,47),(x-74,24),(x-96,50),(x-80,92),(x-43,91)],fill=(157,79,70))
 d.polygon([(x+32,101),(x+49,138),(x+59,135),(x+51,93)],fill=(157,79,70))
d.polygon([(128,133),(640,133),(688,171),(639,197),(132,197),(82,174)],fill=(44,47,46))
d.rectangle((148,129,621,191),fill=(217,214,195),outline=(87,84,77),width=3)
d.text((384,159),'DEPÓSITO DE BEBIDAS',font=font(35),anchor='mm',fill=(80,65,59),stroke_width=1)
letters=Image.new('RGBA',(450,240));ld=ImageDraw.Draw(letters);ld.text((225,113),'JA',font=font(226),anchor='mm',fill=(230,230,217),stroke_width=3,stroke_fill=(64,66,64))
letters=letters.crop(letters.getbbox()).resize((300,320),Image.Resampling.LANCZOS);im.alpha_composite(letters,(234,205));save(im,'ja_mural')
im=Image.new('RGBA',(64,64));d=ImageDraw.Draw(im);d.ellipse((4,3,61,60),fill=(45,156,93));d.ellipse((16,13,48,45),outline='white',width=3);d.polygon([(19,38),(15,49),(28,42)],fill='white');d.arc((23,20,42,36),45,230,fill='white',width=4);save(im,'contact_icon')
im=Image.new('RGB',(512,192),(206,205,176));d=ImageDraw.Draw(im);d.rectangle((0,130,512,192),fill=(55,89,65));d.text((256,38),'DEPÓSITO DE GÁS',font=font(29),anchor='mm',fill=(68,82,68));d.text((256,91),'CASSIANO',font=font(68),anchor='mm',fill=(65,86,66));d.text((256,160),'GÁS • ÁGUA • ENTREGA',font=font(23),anchor='mm',fill=(216,213,174));save(im,'cassiano')
im=Image.new('RGB',(768,160),(44,103,72));d=ImageDraw.Draw(im);d.rectangle((5,5,762,154),outline=(215,202,130),width=4);d.text((384,58),'MERCEARIA E QUITANDA',font=font(43),anchor='mm',fill=(236,224,156));d.text((384,112),'FRUTAS • VERDURAS • CONVENIÊNCIA',font=font(21),anchor='mm',fill=(225,230,207))
for x in [50,715]:
 for j in range(5):d.ellipse((x-20+j%2*14,42+j*13,x+3+j%2*14,66+j*13),fill=[(210,151,49),(179,73,43),(141,163,61)][j%3])
save(im,'market_sign')
print('Street textures:',len(list(OUT.glob('*.png'))))
for metadata in OUT.glob('*.png.import'):
 metadata.write_text(metadata.read_text().replace('mipmaps/generate=false','mipmaps/generate=true'))
