"""Original pixel artwork for the photographed depot reconstruction. No photo tracing/crops.
Run with Python + Pillow. All generated brand names are fictional.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math, random
ROOT=Path(__file__).resolve().parents[1]/'assets/textures/depot'
ROOT.mkdir(exist_ok=True,parents=True)
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf'
REG='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
def font(n):return ImageFont.truetype(FONT,n)
def text(d,xy,s,n,fill,anchor='mm',stroke=0):d.text(xy,s,font=font(n),fill=fill,anchor=anchor,stroke_width=stroke)
def save(im,name):im.save(ROOT/(name+'.png'))
rng=random.Random(412)
# Metric surfaces: one texture repetition = one tile / one steel rib / one sheet.
for name,base in [('wall',(225,224,212)),('floor',(199,199,182)),('roof',(126,136,132)),('wood',(124,98,61)),('counter',(47,49,44))]:
 im=Image.new('RGB',(128,128));p=im.load()
 for y in range(128):
  for x in range(128):
   noise=rng.randrange(-3,4);cloud=round(math.sin(x*.07)*math.sin(y*.045)*3)
   if name=='wall':cloud+=round((math.sin(x*.2+y*.03)+math.sin(x*.03-y*.07))*1.3)
   p[x,y]=tuple(max(0,min(255,c+noise+cloud)) for c in base)
 d=ImageDraw.Draw(im)
 if name=='floor':
  d.line((0,0,127,0),fill=(126,130,123),width=1);d.line((0,0,0,127),fill=(126,130,123),width=1)
  d.line((1,1,127,1),fill=(214,215,201));d.line((1,1,1,127),fill=(214,215,201))
 if name=='roof':
  for x in range(0,128,16):
   d.rectangle((x,0,x+2,127),fill=(88,100,99));d.line((x+3,0,x+3,127),fill=(164,172,165))
   for y in (8,118):d.ellipse((x+5,y,x+7,y+2),fill=(63,73,72))
 if name=='wood':
  for y in range(0,128,9):d.line((0,y,127,y+rng.randrange(-4,5)),fill=(92,71,44))
 save(im,name)
# Contact shadow, shared by shelf bases and appliances. Original generated gradient.
im=Image.new('RGBA',(64,64));px=im.load()
for y in range(64):
 for x in range(64):
  v=max(0,1-max(abs(x-31.5)/31.5,abs(y-31.5)/31.5))
  px[x,y]=(12,17,14,round(v**.5*94))
save(im,'contact')
# Bottle/can side art. y=0 top, y=127 base, body uses a full wrap UV.
styles=[('beer_0','ALVORADA',(90,40,17),(219,186,106)),('beer_1','SERRA',(42,64,25),(224,207,161)),('soda_0','BRISA',(44,27,20),(177,35,33)),('soda_1','GUARÁ',(58,105,37),(34,98,49)),('soda_2','CITRUS',(146,140,41),(225,167,25)),('water','ÁGUA',(104,151,157),(29,100,154)),('can_0','VOLTZ',(32,39,38),(133,172,68)),('can_1','DUPLO',(106,30,25),(181,45,32)),('can_2','SERRA',(50,78,51),(41,112,62)),('spirits','VILA',(129,102,38),(227,218,181))]
for name,title,body,label in styles:
 im=Image.new('RGB',(128,128),body);d=ImageDraw.Draw(im)
 for x in range(128):
  fac=math.cos((x-64)/128*math.pi*2)*.13
  col=tuple(max(0,min(255,round(c*(1+fac)))) for c in body)
  d.line((x,0,x,127),fill=col)
 if name.startswith('can'):
  d.rectangle((0,3,127,123),fill=label);d.rectangle((0,0,127,5),fill=(170,177,165));d.rectangle((0,122,127,127),fill=(129,138,130));
  d.polygon([(0,28),(127,65),(127,74),(0,37)],fill=(207,205,176))
 else:
  d.rectangle((0,42,127,94),fill=label);d.line((0,44,127,44),fill=(235,218,171),width=2);d.line((0,91,127,91),fill=(235,218,171),width=2)
  d.rectangle((0,0,127,8),fill=label)
 text(d,(64,62),title,17,(239,229,191));text(d,(64,82),'FRANCA • BRASIL',6,(228,219,187))
 text(d,(64,107),'350 ml' if name.startswith('can') else ('2 L' if name.startswith('soda') else '600 ml'),8,(229,223,193))
 d.rectangle((100,72,119,88),fill=(227,219,194))
 for x in range(102,119,2):d.line((x,73,x,86),fill=(48,46,34),width=1)
 save(im,name)
# Puffed snack packets, with crimped seals and illustrated contents.
for idx,col in enumerate([(174,141,35),(55,105,46),(151,46,32),(166,104,30),(51,85,132),(196,175,97)]):
 im=Image.new('RGB',(128,128),col);d=ImageDraw.Draw(im)
 d.polygon([(0,22),(127,6),(127,32),(0,45)],fill=(218,202,125))
 for y in [0,3,124,127]:d.line((0,y,127,y),fill=(65,61,40),width=2)
 for x in range(0,128,5):d.line((x,0,x+3,9),fill=(224,210,159));d.line((x,120,x+3,127),fill=(224,210,159))
 text(d,(64,34),'SERRA',22,(243,231,183),stroke=1)
 text(d,(64,55),['BATATA','MILHO','PIMENTA','AMENDOIM','PIPOCA','TORRESMO'][idx],12,(247,229,180))
 for j in range(7):
  x=29+(j%4)*21;y=82+(j//4)*15
  d.ellipse((x-10,y-7,x+10,y+7),fill=(218,173+j*3,73),outline=(137,100,38),width=2)
 text(d,(64,113),'SALGADINHOS  80g',7,(245,232,190))
 save(im,'snack_'+str(idx))
# Hanging toy blister packs: brightly colored headers + plastic/cardboard window.
for idx in range(3):
 im=Image.new('RGB',(96,128),(210,195,131));d=ImageDraw.Draw(im)
 d.rectangle((0,0,95,25),fill=[(36,113,146),(162,49,108),(111,126,37)][idx]);text(d,(48,12),'BRINCA!',14,(245,219,109))
 d.rounded_rectangle((8,32,87,117),radius=5,fill=(169,187,180),outline=(242,236,200),width=3)
 if idx==0:
  d.rectangle((19,66,76,92),fill=(173,49,32));d.rectangle((39,50,69,71),fill=(200,159,39))
  for x in (30,67):d.ellipse((x-10,86,x+10,106),fill=(33,39,35));d.ellipse((x-4,92,x+4,100),fill=(150,157,139))
 elif idx==1:
  d.ellipse((37,42,62,67),fill=(202,156,111));d.polygon([(46,67),(22,103),(78,103),(56,67)],fill=(180,47,112));d.rectangle((42,105,48,118),fill=(205,159,121));d.rectangle((53,105,59,118),fill=(205,159,121))
 else:
  d.ellipse((16,47,78,109),fill=(225,190,45));text(d,(48,78),'A B C',15,(47,104,119))
 d.ellipse((42,4,54,8),fill=(31,39,35));save(im,'toy_'+str(idx))
# Shelf tickets and retail graphics, all readable original text.
for name,fg,bg in [('price',(36,40,31),(220,211,158)),('beer_banner',(235,215,168),(124,73,33)),('soda_banner',(243,233,204),(155,37,32)),('water_banner',(224,237,225),(36,98,133))]:
 im=Image.new('RGB',(256,32),(80,88,70) if name=='price' else bg);d=ImageDraw.Draw(im)
 if name=='price':
  for i in range(8):
   x=i*32;d.rectangle((x+3,2,x+28,29),fill=(232,229,207));text(d,(x+16,9),'OFERTA',5,fg);text(d,(x+16,21),['3,49','5,99','8,50','4,79'][i%4],8,fg)
 else:text(d,(128,17),{'beer_banner':'ALVORADA • PILSEN','soda_banner':'BRISA • BEM GELADA','water_banner':'ÁGUA • LEVE MAIS'}[name],20,fg)
 save(im,name)
# High wall point-of-sale sign.
im=Image.new('RGB',(256,384),(188,163,69));d=ImageDraw.Draw(im);d.rectangle((8,8,247,375),outline=(40,53,43),width=5)
text(d,(128,49),'DEPÓSITO',28,(35,47,39));text(d,(128,84),'JA',63,(35,47,39))
for y,t in [(164,'GELO'),(218,'CARVÃO'),(272,'BEBIDAS')]:text(d,(128,y),t,34,(40,50,39))
text(d,(128,339),'AQUI TEM!',24,(115,39,30));save(im,'poster')
# Counter and back-of-store graphics.
im=Image.new('RGB',(128,128),(26,39,32));d=ImageDraw.Draw(im);text(d,(64,18),'JA • CAIXA 01',10,(170,197,137))
for y,s in [(43,'RETORNÁVEL  8,50'),(59,'GELO       6,00'),(81,'TOTAL     14,50')]:text(d,(7,y),s,9,(156,188,139),anchor='lm')
d.line((7,95,120,95),fill=(131,157,114));text(d,(64,112),'AGUARDANDO',8,(168,182,138));save(im,'register_screen')
im=Image.new('RGB',(128,128),(222,221,201));d=ImageDraw.Draw(im);text(d,(64,17),'ACEITAMOS',12,(24,77,55));text(d,(64,40),'PIX',27,(24,77,55))
for y in range(58,115,5):
 for x in range(34,94,5):
  if rng.random()>.5:d.rectangle((x,y,x+3,y+3),fill=(38,49,42))
save(im,'pix_sign')
im=Image.new('RGB',(128,128),(168,133,77));d=ImageDraw.Draw(im)
for y in [7,118]:d.line((0,y,127,y),fill=(88,68,39),width=2)
d.rectangle((55,0,72,127),fill=(191,164,112));text(d,(64,37),'ALVORADA',16,(58,48,30));text(d,(64,61),'RETORNÁVEIS',9,(58,48,30));text(d,(64,86),'12 × 600 ml',12,(58,48,30));text(d,(64,109),'ESTE LADO PARA CIMA',6,(58,48,30));save(im,'carton')
print('Generated',len(list(ROOT.glob('*.png'))),'original depot textures')
