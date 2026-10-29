"""Original shop lighting graphics, haze noise and worn retail labels. Pillow + NumPy."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageFilter
import numpy as np
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/textures/finish';OUT.mkdir(parents=True,exist_ok=True)
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf'
def font(n):return ImageFont.truetype(FONT,n)
def sign(name,title,subtitle,color):
 im=Image.new('RGB',(768,256),(13,17,24));d=ImageDraw.Draw(im)
 d.rounded_rectangle((10,10,757,245),radius=12,outline=color,width=5)
 d.text((384,95),title,font=font(92),anchor='mm',fill=(246,231,224),stroke_width=2,stroke_fill=color)
 d.text((384,190),subtitle,font=font(29),anchor='mm',fill=color)
 im.save(OUT/(name+'.png'))
sign('open_sign','ABERTO','BEBIDAS • GELO • CONVENIÊNCIA',(244,43,78))
sign('cold_sign','BEM GELADA','PEÇA NO CAIXA',(60,174,210))
im=Image.new('RGB',(256,384),(210,198,167));d=ImageDraw.Draw(im)
for xy,txt,size,col in [((128,52),'GELO',44,(40,76,95)),((128,120),'5 KG',34,(40,76,95)),((128,205),'6,00',65,(163,42,40)),((128,309),'AQUI TEM',26,(42,65,50))]:d.text(xy,txt,font=font(size),anchor='mm',fill=col)
im.save(OUT/'ice_offer.png')
im=Image.new('RGB',(128,256),(180,154,111));d=ImageDraw.Draw(im)
for y in [15,238]:d.line((0,y,127,y),fill=(66,56,39),width=3)
for y,txt,n in [(55,'CARVÃO',25),(100,'VEGETAL',18),(171,'3 KG',32),(215,'SECO',12)]:d.text((64,y),txt,font=font(n),anchor='mm',fill=(49,46,32))
im.save(OUT/'charcoal_bag.png')
rng=np.random.default_rng(707558);noise=np.zeros((256,256),np.float32)
for size,weight in [(4,.42),(8,.29),(16,.18),(32,.11)]:
 layer=Image.fromarray(rng.integers(0,256,(size,size),dtype=np.uint8)).resize((256,256),Image.Resampling.BICUBIC)
 noise+=np.asarray(layer)*weight
Image.fromarray(np.uint8(noise)).save(OUT/'haze_noise.png')
im=Image.new('RGBA',(128,128));d=ImageDraw.Draw(im)
for i in range(15):
 x=int(rng.integers(8,118));d.line((x,12,x+int(rng.integers(-8,9)),116),fill=(224,232,228,int(rng.integers(18,65))),width=1)
d.rounded_rectangle((6,4,122,124),radius=10,outline=(230,236,221,58),width=2);im.save(OUT/'plastic_film.png')
for meta in OUT.glob('*.png.import'):meta.write_text(meta.read_text().replace('mipmaps/generate=false','mipmaps/generate=true'))
print('Finish artwork:',len(list(OUT.glob('*.png'))))
