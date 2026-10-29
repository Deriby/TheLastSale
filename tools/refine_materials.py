"""Second surface pass: physical finishes and original printed retail artwork.

Called by make_surface_materials.py. No photographs are cropped or modified.
Color maps contain pigment; ORM separates wear, varnish, paper, PET and metal.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np
import math, json, hashlib


def refine_surfaces(api):
    noise, layers = api['noise'], api['layers']
    grain_fn, lines, export = api['warped_grain'], api['mask_lines'], api['export']
    rng = np.random.default_rng(13001)
    w, h = 2048, 1024
    x, y = np.meshgrid(np.arange(w) / w, np.arange(h) / h)
    warp = noise(w, h, 5, 7, rng) * .009 + noise(w, h, 11, 18, rng) * .002
    knots = np.zeros((h, w))
    for cx, cy in [(.19, .28), (.68, .77)]:
        dx, dy = (x-cx+.5) % 1-.5, (y-cy+.5) % 1-.5
        warp += dy*np.exp(-(dx/.075)**2-(dy/.055)**2)*1.3
        radius = np.sqrt((dx/.026)**2+(dy/.012)**2)
        knots -= np.exp(-radius**2)*14
    fibers = grain_fn(x, y, warp, 19, 340, rng)
    vessels = np.maximum(0, -grain_fn(x, y, warp, 38, 720, rng)-1.05)
    growth = grain_fn(x, y, warp, 9, 54, rng)
    broad = noise(w, h, 8, 13, rng)
    scratches = lines(w, h, rng, 180, 22, 1)
    wipe = np.maximum(0, noise(w, h, 7, 9, rng)-.3)
    rings = np.zeros((h, w))
    for cx, cy in [(.32, .64), (.83, .34)]:
        radius = np.sqrt((((x-cx+.5) % 1-.5)/.025)**2 + (((y-cy+.5) % 1-.5)/.050)**2)
        rings += np.exp(-((radius-1)/.055)**2)*.30
    color = fibers*3.3 + growth*4 + broad*2.2 - vessels*6 + knots
    rgb = np.stack((139+color, 106+color*.83, 70+color*.64), 2)
    rgb -= rings[..., None]*np.array([5, 4, 3])
    height = fibers*.000016 - vessels*.000025 - scratches*.000025
    rough = np.clip(.34 + broad*.027 + wipe*.075 + scratches*.24 + rings*.25, .26, .67)
    export('wood', rgb, height, rough, (2.4, 1.2))

    # Unvarnished pallet timber is a separate finish from the checkout veneer.
    w, h = 1024, 512
    x, y = np.meshgrid(np.arange(w)/w, np.arange(h)/h)
    fibers = grain_fn(x, y, noise(w, h, 5, 8, rng)*.008, 12, 170, rng)
    pores = np.maximum(0, -grain_fn(x, y, np.zeros_like(x), 29, 240, rng)-.6)
    broad = noise(w, h, 7, 9, rng)
    color = fibers*7 + broad*5 - pores*10
    rgb = np.stack((153+color, 135+color*.92, 106+color*.8), 2)
    export('pallet_wood', rgb, fibers*.00013-pores*.00018,
           np.clip(.84+broad*.025+pores*.035, .74, .97), (2.4, 1.2))

    w = h = 1024
    x, y = np.meshgrid(np.arange(w)/w, np.arange(h)/h)
    for name, seed in [('ceramic', 13010), ('wall', 13011), ('plaster', 13012),
                       ('asphalt', 13013), ('paving', 13014)]:
        rng = np.random.default_rng(seed)
        cloud = layers(w, h, rng, [(4, 4, .7), (13, 13, .3), (45, 45, .09)])
        micro = noise(w, h, 280, 280, rng)
        ao = np.ones((h, w))
        if name == 'ceramic':
            u, v = (x*4) % 1, (y*4) % 1
            edge = np.minimum.reduce([u, 1-u, v, 1-v])
            grout = np.clip((.012-edge)/.008, 0, 1)
            bevel = np.exp(-((edge-.014)/.006)**2)
            tile = rng.normal(0, 2, (4, 4))[(y*4).astype(int), (x*4).astype(int)]
            # Fired glaze mottling and cleaning haze, below the scale of dirt decals.
            glaze = noise(w, h, 33, 47, rng)*1.4 + cloud*3.1
            haze = np.clip(noise(w, h, 10, 9, rng)-.1, 0, 1)
            rgb = np.stack((184+tile+glaze, 185+tile+glaze, 178+tile+glaze), 2)
            rgb = rgb*(1-grout[..., None]) + np.array([121, 126, 119])*grout[..., None]
            height = micro*.000008 - grout*.00085 - bevel*.00008
            rough = .38 + cloud*.025 + haze*.105 + grout*.45
            span = (2.4, 2.4); ao = 1-grout*.14
        elif name in ['wall', 'plaster']:
            outside = name == 'plaster'
            pores = np.maximum(0, -micro-.8)
            trowel = noise(w, h, 31, 7, rng)
            soil = np.maximum(0, noise(w, h, 9, 17, rng)-.45)
            base = np.array([228, 227, 218] if outside else [216, 215, 205])
            rgb = base + (cloud*2.2 + trowel*.8 + micro*.45)[..., None]
            rgb -= soil[..., None]*np.array([4, 4.8, 5.3])
            height = micro*(.00018 if outside else .000035)-pores*.00007
            rough = .91 + cloud*.015 + pores*.025
            span = (2.8, 2.8)
        elif name == 'asphalt':
            # Rounded aggregate, bitumen pockets and polished traffic patches.
            aggregate = noise(w, h, 360, 360, rng)
            stone = np.maximum(0, aggregate-.1)
            pits = np.maximum(0, -aggregate-.7)
            cracks = lines(w, h, rng, 5, 140, 1)
            polished = np.clip(noise(w, h, 5, 9, rng)-.2, 0, 1)
            shade = cloud*3.3 + stone*7 - pits*2 - cracks*14
            rgb = np.stack((57+shade, 59+shade, 59+shade), 2)
            height = stone*.0005 - pits*.0003 - cracks*.0008
            rough = .85 + cloud*.025 - polished*.13 + pits*.025
            span = (4., 4.); ao = 1-np.minimum(pits, 1)*.09-cracks*.07
        else:
            pits = np.maximum(0, -micro-.65)
            sand = noise(w, h, 190, 190, rng)
            cracks = lines(w, h, rng, 3, 105, 1)
            shade = cloud*4 + sand*1.4-pits*4-cracks*15
            rgb = np.stack((164+shade, 160+shade, 149+shade), 2)
            height = sand*.00013-pits*.00025-cracks*.0007
            rough = .86+cloud*.025+pits*.02
            span = (2., 2.); ao = 1-np.minimum(pits, 1)*.08-cracks*.06
        export(name, rgb, height, np.clip(rough, .2, .99), span, ao=ao)

    for index, name in enumerate(['painted_metal', 'steel', 'plastic', 'glass']):
        w = h = 512; rng = np.random.default_rng(13030+index)
        cloud = noise(w, h, 7, 7, rng)
        micro = noise(w, h, 180, 180, rng)
        scratches = lines(w, h, rng, 45, 13, 1)
        if name == 'steel':
            brush = noise(w, h, 3, 220, rng)
            pigment = 221+brush*2
            height = brush*.000009
            rough = .30+brush*.04+scratches*.16
            span = (.6, .6); metal = .94
        elif name == 'painted_metal':
            pigment = 247+cloud*.8-scratches*13
            height = micro*.000013-scratches*.000018
            rough = .36+cloud*.024+scratches*.26
            span = (.85, .85); metal = 0
        elif name == 'plastic':
            pigment = 247+cloud*.6-scratches*8
            height = micro*.000015
            rough = .53+cloud*.026+scratches*.17
            span = (.6, .6); metal = 0
        else:
            # Faint handling marks change gloss, without painted-on highlights.
            wipe = np.maximum(0, noise(w, h, 10, 4, rng)-.25)
            pigment = 253+cloud*.3
            height = np.zeros((h, w))
            rough = .10+wipe*.10+scratches*.04
            span = (1.4, 1.4); metal = 0
        export(name, np.stack([pigment]*3, 2), height, np.clip(rough, .07, .9), span, metal=metal)

    apply_scanned_surfaces(api)


def apply_scanned_surfaces(api):
    """Use bundled, hash-checked CC0 scans for the larger visible surfaces."""
    root = api['ROOT']; source = root/'resources/material_sources'
    manifest = json.loads((source/'sources.json').read_text())
    for record in manifest['files']:
        assert hashlib.sha256((source/record['local_file']).read_bytes()).hexdigest() == record['sha256']
    profiles = [('wood', 'wood_table_001', [139, 106, 70], (2.4, 1.2), .85),
                ('plaster', 'painted_plaster_wall', [228, 227, 218], (2., 2.), .42),
                ('asphalt', 'asphalt_02', [57, 59, 59], (3., 3.), .55),
                ('paving', 'concrete_floor_02', [164, 160, 149], (2., 2.), .60)]
    for name, asset, base, span, contrast in profiles:
        images = [Image.open(source/(asset+'_'+kind+'.jpg')).convert('RGB') for kind in ['Diffuse', 'nor_gl', 'arm']]
        if name == 'wood':images = [im.transpose(Image.Transpose.ROTATE_90) for im in images]
        color, normal, orm = [np.asarray(im, dtype=np.float64) for im in images]
        color = np.clip(np.array(base)+(color-np.median(color, axis=(0, 1)))*contrast, 0, 255)
        normal = normal/255*2-1
        if name == 'wood':
            nx = -normal[..., 1].copy();normal[..., 1] = normal[..., 0];normal[..., 0] = nx
        normal /= np.maximum(np.linalg.norm(normal, axis=2, keepdims=True), .001)
        orm /= 255
        rough = np.clip(.30+orm[..., 1]*.25, .30, .55) if name == 'wood' else np.clip(orm[..., 1], .65, .97)
        ao = 1-(1-orm[..., 0])*.25
        api['export'](name, color, np.zeros_like(rough), rough, span, ao=ao)
        Image.fromarray(np.uint8(np.clip((normal*.5+.5)*255, 0, 255))).save(api['OUT']/(name+'_normal.png'))
        record = next(r for r in api['reports'] if r['surface'] == name)
        record['source'] = 'Poly Haven / '+asset+' / CC0-1.0'


FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf'
REGULAR = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'


def label(draw, xy, text, size, color, regular=False):
    draw.text(xy, text, font=ImageFont.truetype(REGULAR if regular else FONT, size),
              fill=color, anchor='mm')


def barcode(draw, box, rng):
    x, y, width, height = box
    draw.rectangle((x, y, x+width, y+height), fill=(221, 218, 198))
    for at in range(x+4, x+width-3, 3):
        draw.line((at, y+4, at, y+height-4), fill=(42, 43, 37), width=int(rng.integers(1, 3)))


def save_retail(root, name, image, rough, metallic):
    path = root/'assets/textures/depot'
    image.save(path/(name+'.png'))
    orm = np.stack((np.ones_like(rough), np.clip(rough, .08, 1), metallic), 2)
    # Finish masks need less resolution than print; halve each dimension to
    # avoid spending the artwork's full texture budget on broad gloss regions.
    Image.fromarray(np.uint8(np.clip(orm*255, 0, 255))).resize((256, 256), Image.Resampling.BOX).save(path/(name+'_orm.png'))


def refine_retail(root, noise):
    """One material per existing SKU; no extra transparent shells or draw calls."""
    w = h = 512
    styles = [
        ('beer_0', 'ALVORADA', (72, 38, 19), (204, 178, 112)),
        ('beer_1', 'SERRA', (43, 61, 30), (199, 195, 157)),
        ('soda_0', 'BRISA', (44, 29, 23), (162, 36, 34)),
        ('soda_1', 'GUARÁ', (58, 94, 40), (41, 90, 48)),
        ('soda_2', 'CITRUS', (146, 133, 43), (206, 160, 34)),
        ('water', 'ÁGUA', (139, 170, 175), (41, 99, 145)),
        ('can_0', 'VOLTZ', (37, 42, 39), (116, 149, 60)),
        ('can_1', 'DUPLO', (101, 32, 29), (168, 46, 37)),
        ('can_2', 'SERRA', (48, 72, 49), (48, 105, 64)),
        ('spirits', 'VILA', (114, 91, 41), (212, 200, 165)),
    ]
    for index, (name, title, body, ink) in enumerate(styles):
        rng = np.random.default_rng(13100+index)
        cloud = noise(w, h, 19, 23, rng)
        pigment = np.array(body)+cloud[..., None]*.65
        im = Image.fromarray(np.uint8(np.clip(pigment, 0, 255)))
        d = ImageDraw.Draw(im)
        can = name.startswith('can')
        beer = name.startswith('beer')
        rough = np.full((h, w), .21 if beer or name == 'spirits' else .26)
        rough += cloud*.007
        metallic = np.zeros((h, w))
        cap = ink if not beer else (149, 136, 93)
        d.rectangle((0, 0, w-1, 16), fill=cap)
        for x in range(0, w, 8):d.line((x, 1, x, 14), fill=tuple(int(c*.8) for c in cap))
        rough[:17] = .43; metallic[:17] = .65 if beer else 0
        if can:
            d.rectangle((0, 17, w-1, h-18), fill=ink)
            d.rectangle((0, 0, w-1, 16), fill=(175, 181, 178))
            d.rectangle((0, h-17, w-1, h-1), fill=(151, 158, 153))
            rough[:] = .32; rough[:17] = .25; rough[-17:] = .28
            metallic[:] = .35; metallic[:17] = .9; metallic[-17:] = .9
            d.polygon([(0, 88), (w-1, 176), (w-1, 204), (0, 116)], fill=(211, 208, 181))
            top, bottom = 130, 373
        else:
            top, bottom = 186, 365
            d.rectangle((0, top, w-1, bottom), fill=ink)
            for edge in [top+5, bottom-6]:d.line((0, edge, w-1, edge), fill=(219, 211, 173), width=3)
            rough[top:bottom+1] = .61 if beer else .44
        light = (231, 226, 202)
        label(d, (256, top+27), 'FRANCA • DESDE 1987', 10, light, True)
        title_size = 42 if len(title) > 6 else 54
        label(d, (256, (top+bottom)*.5-6), title, title_size, light)
        subtitle = 'PILSEN • PURO MALTE' if beer else ('SEM GÁS' if name == 'water' else 'SABOR ORIGINAL')
        label(d, (256, bottom-35), subtitle, 13, light)
        label(d, (256, bottom-17), 'CONSERVAR EM LOCAL FRESCO', 8, light, True)
        volume = '350 ml' if can else ('2 L' if name.startswith('soda') else '500 ml' if name == 'water' else '600 ml')
        label(d, (256, 433), volume, 18, (179, 181, 157))
        barcode(d, (426, top+31, 64, 100), rng)
        for row in range(9):
            d.line((14, top+29+row*12, 78-(row % 3)*7, top+29+row*12), fill=light, width=1)
        # Molded PET ribs are finish changes; the mesh and opacity stay unchanged.
        if name == 'water':
            for y in [51, 66, 81, 100, 118, 391, 408, 455, 473]:
                rough[y:y+2] = .38
        save_retail(root, name, im, rough, metallic)

    colors = [(166, 133, 42), (53, 95, 47), (149, 46, 35),
              (161, 98, 37), (46, 76, 116), (184, 162, 91)]
    titles = ['BATATA', 'MILHO', 'PIMENTA', 'AMENDOIM', 'PIPOCA', 'TORRESMO']
    xx, yy = np.meshgrid(np.arange(w)/w, np.arange(h)/h)
    for index, color in enumerate(colors):
        rng = np.random.default_rng(13200+index)
        cloud = noise(w, h, 14, 18, rng)
        pigment = np.array(color)+cloud[..., None]*.8
        im = Image.fromarray(np.uint8(np.clip(pigment, 0, 255)));d = ImageDraw.Draw(im)
        d.polygon([(0, 60), (w-1, 17), (w-1, 138), (0, 172)], fill=(214, 194, 122))
        label(d, (256, 100), 'SERRA', 68, (242, 230, 185))
        label(d, (256, 172), titles[index], 31, (239, 226, 185))
        label(d, (256, 203), 'CROCANTE • FEITO NO BRASIL', 10, (226, 216, 184), True)
        # Original food illustration with pores, seasoning and curved surfaces.
        for piece in range(13):
            cx, cy = rng.uniform(142, 370), rng.uniform(265, 374)
            a, b = rng.uniform(27, 49), rng.uniform(17, 29)
            if index == 3:a *= .60; b *= .70
            angle = rng.uniform(-1.2, 1.2)
            dx, dy = (xx*w-cx), (yy*h-cy)
            u = (dx*np.cos(angle)+dy*np.sin(angle))/a
            v = (-dx*np.sin(angle)+dy*np.cos(angle))/b
            radius = u*u+v*v
            mask = radius < 1
            bulge = np.sqrt(np.maximum(0, 1-radius))
            seasoning = rng.random((h, w))
            tone = bulge*32-u*10-v*7 + np.sin(u*27)*2 - (seasoning > .975)*36
            base = np.array([190, 135, 49] if index != 5 else [175, 121, 65])
            food = np.clip(base+tone[..., None], 0, 255).astype(np.uint8)
            old = np.asarray(im).copy();old[mask] = food[mask];im = Image.fromarray(old)
        d = ImageDraw.Draw(im)
        for y in [4, 12, 20, 491, 499, 507]:d.line((0, y, w-1, y), fill=(120, 114, 89), width=2)
        for x in range(0, w, 9):
            d.line((x, 0, x+2, 25), fill=(212, 204, 170), width=2)
            d.line((x, 487, x+2, 511), fill=(212, 204, 170), width=2)
        label(d, (256, 425), 'SALGADINHOS • 80 g', 18, (235, 224, 194))
        label(d, (256, 451), 'SABOR CASEIRO   |   EMBALAGEM RECICLÁVEL', 8, (231, 218, 180), True)
        barcode(d, (413, 376, 69, 91), rng)
        creases = np.abs(np.sin(xx*41+np.sin(yy*8)*2))**28
        rough = np.clip(.33+cloud*.018+creases*.23, .23, .64)
        rough[:26] = .51; rough[-26:] = .51
        save_retail(root, 'snack_'+str(index), im, rough, np.full((h, w), .07))

    # Printed labels and tape sit on a coarse cardboard carrier.
    rng = np.random.default_rng(13300)
    cloud = noise(w, h, 26, 26, rng);fiber = noise(w, h, 230, 230, rng)
    rgb = np.array([158, 132, 94])+(cloud*3+fiber*2)[..., None]
    im = Image.fromarray(np.uint8(np.clip(rgb, 0, 255)));d = ImageDraw.Draw(im)
    d.rectangle((224, 0, 283, h-1), fill=(180, 155, 112))
    label(d, (256, 117), 'ALVORADA', 48, (64, 52, 34))
    label(d, (256, 198), 'RETORNÁVEIS', 28, (64, 52, 34))
    label(d, (256, 296), '12 × 600 ml', 40, (64, 52, 34))
    label(d, (256, 385), 'ESTE LADO PARA CIMA', 17, (64, 52, 34))
    barcode(d, (29, 408, 146, 62), rng)
    rough = np.clip(.9+cloud*.02, .84, .97);rough[:, 224:284] = .49
    save_retail(root, 'carton', im, rough, np.zeros((h, w)))

    # Filtering must apply to the artwork too, not only to the PBR maps.
    for path in (root/'assets/textures/depot').glob('*.png.import'):
        if path.stem.removesuffix('.png') in {x[0] for x in styles} | {'snack_'+str(i) for i in range(6)} | {'carton'} or path.name.endswith('_orm.png.import'):
            text = path.read_text().replace('mipmaps/generate=false', 'mipmaps/generate=true')
            text = text.replace('compress/normal_map=0', 'compress/normal_map=2')
            path.write_text(text)
