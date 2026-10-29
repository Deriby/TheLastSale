"""Metric, tileable original PBR surfaces; palette/scale guided by depot photos.
Python + Pillow + NumPy. Does not modify photos, models or the earlier texture sets.
Albedo contains surface color only. ORM = occlusion/red, roughness/green, metal/blue.
"""
from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np
import json, math

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/textures/surfaces';OUT.mkdir(parents=True,exist_ok=True)
reports=[]

def noise(w,h,nx,ny,rng):
    grid=rng.normal(0,1,(ny,nx))
    x=np.arange(w)*nx/w;y=np.arange(h)*ny/h
    ix=x.astype(int);iy=y.astype(int);u=x-ix;v=y-iy
    u=u*u*u*(u*(u*6-15)+10);v=v*v*v*(v*(v*6-15)+10)
    a=grid[iy[:,None]%ny,ix[None,:]%nx]*(1-u)+grid[iy[:,None]%ny,(ix[None,:]+1)%nx]*u
    b=grid[(iy[:,None]+1)%ny,ix[None,:]%nx]*(1-u)+grid[(iy[:,None]+1)%ny,(ix[None,:]+1)%nx]*u
    return a*(1-v[:,None])+b*v[:,None]

def layers(w,h,rng,scales):
    return sum(noise(w,h,nx,ny,rng)*weight for nx,ny,weight in scales)

def warped_grain(xx,yy,warp,nx,ny,rng):
    grid=rng.normal(0,1,(ny,nx));x=xx*nx;y=(yy+warp)*ny
    ix=np.floor(x).astype(int);iy=np.floor(y).astype(int);u=x-ix;v=y-iy
    u=u*u*(3-2*u);v=v*v*(3-2*v)
    a=grid[iy%ny,ix%nx]*(1-u)+grid[iy%ny,(ix+1)%nx]*u
    b=grid[(iy+1)%ny,ix%nx]*(1-u)+grid[(iy+1)%ny,(ix+1)%nx]*u
    return a*(1-v)+b*v

def mask_lines(w,h,rng,count,length,width=1):
    im=Image.new('L',(w,h));d=ImageDraw.Draw(im)
    for i in range(count):
        x,y=rng.uniform(0,w),rng.uniform(0,h);angle=rng.uniform(0,math.tau)
        points=[(x,y)]
        for j in range(5):
            x+=math.cos(angle)*length/5;y+=math.sin(angle)*length/5;angle+=rng.normal(0,.34);points.append((x,y))
        for ox in [-w,0,w]:
            for oy in [-h,0,h]:d.line([(a+ox,b+oy) for a,b in points],fill=int(rng.integers(90,240)),width=width)
    return np.asarray(im,dtype=float)/255

def export(name,rgb,height,rough,span,metal=0,ao=None):
    h,w=height.shape
    dx=(np.roll(height,-1,1)-np.roll(height,1,1))*w/(2*span[0])
    dy=(np.roll(height,-1,0)-np.roll(height,1,0))*h/(2*span[1])
    normal=np.stack((-dx,dy,np.ones_like(dx)),axis=2)
    normal/=np.linalg.norm(normal,axis=2,keepdims=True)
    normal=normal*.5+.5
    if ao is None:ao=np.ones_like(rough)
    orm=np.stack((np.clip(ao,0,1),np.clip(rough,.05,1),np.full_like(rough,metal)),axis=2)
    for suffix,array in [('albedo',rgb/255),('normal',normal),('orm',orm)]:
        assert np.isfinite(array).all(),(name,suffix)
        Image.fromarray(np.uint8(np.clip(array*255,0,255))).save(OUT/(name+'_'+suffix+'.png'))
    reports.append({'surface':name,'pixels':[w,h],'repeat_m':list(span),'roughness_range':[round(float(rough.min()),3),round(float(rough.max()),3)],'metallic':metal})

# The photographed counter is worn varnished brown wood, not regular sine bands.
w,h=2048,1024;rng=np.random.default_rng(80801)
xx,yy=np.meshgrid(np.arange(w)/w,np.arange(h)/h)
warp=noise(w,h,4,8,rng)*.014+noise(w,h,8,16,rng)*.003
knot=np.zeros((h,w))
for cx,cy in [(.28,.35),(.81,.79)]:
    dx=(xx-cx+.5)%1-.5;dy=(yy-cy+.5)%1-.5
    warp+=dy*np.exp(-(dx/.09)**2-(dy/.055)**2)*1.5
    radius=np.sqrt((dx/.026)**2+(dy/.015)**2)
    knot-=np.exp(-radius*radius)*17
    knot+=np.sin(radius*12)*np.exp(-radius*radius*.4)*2
grain=warped_grain(xx,yy,warp,5,180,rng)+warped_grain(xx,yy,warp,13,540,rng)*.4
broad=layers(w,h,rng,[(3,9,1),(9,35,.35),(32,180,.12)])
vessels=np.maximum(0,warped_grain(xx,yy,warp,29,600,rng)-1.1)*4
color=grain*4+broad*8-vessels+knot
scratches=mask_lines(w,h,rng,450,35,1)
height=grain*.000035+broad*.000025-scratches*.00006
rgb=np.stack([138+color+scratches*8,107+color*.81+scratches*7,74+color*.63+scratches*5],2)
rough=np.clip(.43+noise(w,h,4,6,rng)*.055+scratches*.20,.30,.69)
export('wood',rgb,height,rough,(2.4,1.2))

w=h=1024
for index,name in enumerate(['ceramic','wall','plaster','asphalt','paving']):
    rng=np.random.default_rng(80810+index)
    cloud=layers(w,h,rng,[(3,3,1),(9,9,.4),(31,31,.13)])
    fine=noise(w,h,220,220,rng);pores=noise(w,h,380,380,rng)
    ao=None
    if name=='ceramic':
        xx,yy=np.meshgrid(np.arange(w)/w,np.arange(h)/h)
        edges=np.minimum.reduce([np.mod(xx*4,1),1-np.mod(xx*4,1),np.mod(yy*4,1),1-np.mod(yy*4,1)])
        grout=np.clip((.013-edges)/.010,0,1)
        variation=rng.normal(0,3,(4,4))[np.minimum((yy*4).astype(int),3),np.minimum((xx*4).astype(int),3)]
        shade=cloud*9+fine*.7+variation
        rgb=np.stack((179+shade,181+shade,174+shade*.96),2)*(1-grout[:,:,None]*.26)
        height=cloud*.000035+fine*.000008-grout*.0011
        rough=np.clip(.47+cloud*.026+grout*.35,.35,.88);span=(2.4,2.4);ao=1-grout*.12
    elif name in ['wall','plaster']:
        outside=name=='plaster';pitting=np.maximum(0,-pores-.9)
        shade=cloud*(3.2 if outside else 1.5)+fine*(1.8 if outside else .7)
        base=(230,230,222) if outside else (211,211,201)
        rgb=np.stack([c+shade for c in base],2)
        height=fine*(.00032 if outside else .000075)-pitting*.00012
        rough=np.clip(.90+cloud*.015+pitting*.04,.81,.99);span=(2.8,2.8)
    elif name=='asphalt':
        im=Image.new('L',(w,h));d=ImageDraw.Draw(im)
        for i in range(54000):
            x,y=rng.integers(0,w,2);r=int(rng.choice([0,0,0,1,1,1,2]));value=int(rng.integers(35,205))
            for ox in [-w,0,w]:
                for oy in [-h,0,h]:d.polygon([(x-r+ox,y+oy),(x+ox,y-r+oy),(x+r+ox,y+1+oy),(x+ox,y+r+oy)],fill=value)
        stone=np.asarray(im,dtype=float)/255;cracks=mask_lines(w,h,rng,7,185,2)
        shade=cloud*5.5+stone*7+fine*1.7-cracks*20
        rgb=np.stack((60+shade,63+shade,63+shade),2)
        height=stone*.00065+fine*.00018-cracks*.0015
        rough=np.clip(.89+cloud*.022-stone*.035+cracks*.04,.74,.98);span=(4,4);ao=1-cracks*.14
    else:
        pits=np.maximum(0,-pores-1.1);cracks=mask_lines(w,h,rng,3,125,1)
        shade=cloud*6+fine*2.1-pits*11-cracks*24
        rgb=np.stack((166+shade,162+shade,150+shade*.96),2)
        height=fine*.00028-pits*.0006-cracks*.0012
        rough=np.clip(.88+cloud*.02+pits*.025,.77,.98);span=(2.0,2.0);ao=1-np.minimum(pits,1)*.06-cracks*.12
    export(name,rgb,height,rough,span,ao=ao)

# Neutral color carriers preserve the painted tint of each shop fixture.
for index,name in enumerate(['painted_metal','steel','plastic','rubber','carpaint','glass']):
    w=h=512;rng=np.random.default_rng(80830+index)
    cloud=noise(w,h,5,5,rng);grain=noise(w,h,180,180,rng)
    scratches=mask_lines(w,h,rng,80,14,1)
    if name=='painted_metal':
        rgb=np.stack([244+cloud*2-scratches*17]*3,2);height=grain*.000025-scratches*.00004
        rough=np.clip(.49+cloud*.025+scratches*.20,.40,.77);metal=.08;span=(.85,.85)
    elif name=='steel':
        brush=noise(w,h,2,220,rng);rgb=np.stack([210+brush*3]*3,2);height=brush*.000008
        rough=np.clip(.35+brush*.035+scratches*.12,.23,.58);metal=.82;span=(.6,.6)
    elif name=='plastic':
        rgb=np.stack([242+cloud*1.6-scratches*8]*3,2);height=grain*.000025
        rough=np.clip(.60+cloud*.024+scratches*.12,.49,.78);metal=0;span=(.6,.6)
    elif name=='rubber':
        rgb=np.stack([235+cloud*3]*3,2);height=grain*.00008
        rough=np.clip(.93+cloud*.018,.86,.99);metal=0;span=(.5,.5)
    elif name=='carpaint':
        rgb=np.stack([249+cloud*1.4]*3,2);height=grain*.000012
        rough=np.clip(.32+cloud*.018+scratches*.04,.25,.43);metal=.32;span=(1.2,1.2)
    else:
        rgb=np.stack([250+cloud*.6]*3,2);height=grain*.000002
        rough=np.clip(.14+np.maximum(0,cloud)*.06+scratches*.04,.12,.29);metal=.03;span=(1.4,1.4)
    export(name,rgb,height,rough,span,metal=metal)

for index,name in enumerate(['brick','azulejo','bark']):
    w=h=1024 if name=='brick' else 512;rng=np.random.default_rng(90910+index)
    xx,yy=np.meshgrid(np.arange(w)/w,np.arange(h)/h)
    fine=noise(w,h,180,180,rng);cloud=noise(w,h,8,8,rng)
    if name=='brick':
        row=np.floor(yy*24).astype(int);u=np.mod(xx*10+(row%2)*.5,1);v=np.mod(yy*24,1)
        edge=np.minimum(np.minimum(u,1-u)*.24,np.minimum(v,1-v)*.10)
        mortar=np.clip((.004-edge)/.0025,0,1)
        variation=rng.normal(0,10,(24,11))[row%24,np.floor((xx*10+(row%2)*.5)%11).astype(int)]
        shade=variation+cloud*3+fine*2
        rgb=np.stack((151+shade,93+shade*.65,65+shade*.45),2)
        rgb=rgb*(1-mortar[:,:,None])+np.array([151,148,134])*mortar[:,:,None]
        height=fine*.00015-mortar*.003;rough=np.clip(.89+cloud*.015+mortar*.06,.79,.99);span=(2.4,2.4);ao=1-mortar*.15
    elif name=='azulejo':
        row=np.floor(yy*4).astype(int);col=np.floor(xx*4).astype(int)
        edge=np.minimum.reduce([np.mod(xx*4,1),1-np.mod(xx*4,1),np.mod(yy*4,1),1-np.mod(yy*4,1)])
        grout=np.clip((.019-edge)/.013,0,1);blue=(row+col)%2
        rgb=np.stack((219-blue*106+cloud*2,222-blue*68+cloud*2,213-blue*39+cloud*2),2)
        rgb=rgb*(1-grout[:,:,None])+np.array([156,165,156])*grout[:,:,None]
        height=fine*.000012-grout*.0009;rough=np.clip(.36+cloud*.018+grout*.45,.27,.90);span=(.6,.6);ao=1-grout*.08
    else:
        fibers=noise(w,h,68,4,rng)+noise(w,h,190,15,rng)*.2
        fissure=np.maximum(0,-fibers-.55)
        shade=fibers*8+cloud*4-fissure*12
        rgb=np.stack((122+shade,113+shade*.92,94+shade*.8),2)
        height=fibers*.00065-fissure*.0014;rough=np.clip(.94+cloud*.012,.87,.99);span=(1,1);ao=1-np.clip(fissure,0,1)*.14
    export(name,rgb,height,rough,span,ao=ao)

for metadata in OUT.glob('*.png.import'):
    text=metadata.read_text().replace('mipmaps/generate=false','mipmaps/generate=true')
    target='1' if metadata.name.endswith('_normal.png.import') else '2'
    for old in ['0','1','2']:text=text.replace('compress/normal_map='+old,'compress/normal_map='+target)
    metadata.write_text(text)
(ROOT/'docs/surface_report.json').write_text(json.dumps(reports,indent=2)+'\n')
print('Original PBR surfaces:',len(reports),'| maps:',len(list(OUT.glob('*.png'))))
