"""Original artwork and ambient sounds for the photo-based shop revision.
Requires Pillow. No photo pixels, third-party game assets or recorded music.
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import math, random, struct, wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/textures/details'
OUT.mkdir(parents=True, exist_ok=True)
rng = random.Random(55805)
FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf'
def label(draw, xy, words, size, color, anchor='mm'):
    draw.text(xy, words, font=ImageFont.truetype(FONT, size), fill=color, anchor=anchor)
def save(im, name):
    im.save(OUT / (name + '.png'))

im = Image.new('RGB', (512, 256)); px = im.load()
for y in range(256):
    for x in range(512):
        grain = math.sin(y * .75 + math.sin(x * .015) * 1.7) * 6 + math.sin(y * 2.1 + x * .025) * 3
        noise = rng.randrange(-5, 6)
        px[x, y] = tuple(max(0, min(255, int(c + grain + noise))) for c in (124, 95, 61))
save(im, 'worktop')
im = Image.new('RGB', (576, 384), (192, 194, 184)); d = ImageDraw.Draw(im)
d.rectangle((0, 0, 575, 35), fill=(42, 66, 111)); label(d, (20, 17), 'JA  |  FRENTE DE CAIXA', 18, (232, 235, 223), 'lm')
for i, word in enumerate(['PRODUTO', 'QUANT.', 'VALOR', 'TOTAL']):
    x = [12, 338, 420, 501][i]; d.rectangle((x, 48, x + (316 if i == 0 else 67), 76), fill=(125, 145, 169)); label(d, (x + 6, 62), word, 12, (24, 33, 42), 'lm')
for row in range(8):
    y = 79 + row * 23; d.rectangle((12, y, 563, y + 21), fill=(219, 221, 210) if row % 2 else (206, 210, 204))
    if row < 3:
        label(d, (18, y + 11), ['RETORNAVEL 600 ML', 'AGUA MINERAL', 'GELO 5 KG'][row], 13, (39, 47, 52), 'lm')
        label(d, (548, y + 11), ['8,50', '3,50', '6,00'][row], 14, (39, 47, 52), 'rm')
d.rectangle((26, 125, 550, 295), fill=(213, 209, 184), outline=(67, 77, 108), width=4)
label(d, (288, 176), 'JA', 64, (109, 51, 64)); label(d, (288, 238), 'CAIXA DISPONIVEL', 25, (66, 65, 58))
label(d, (20, 323), 'TOTAL', 22, (34, 39, 47), 'lm'); label(d, (554, 323), 'R$ 18,00', 29, (29, 42, 60), 'rm')
label(d, (288, 368), 'BUSCA PRODUTO     PAGAMENTO     CANCELAR', 13, (53, 59, 58)); save(im, 'pos_screen')
im = Image.new('RGB', (512, 256), (226, 223, 207)); d = ImageDraw.Draw(im)
for y, text in [(44, 'NÃO VENDEMOS FIADO.'), (106, 'POR FAVOR, NÃO'), (168, 'INSISTIR. OBRIGADO!')]: label(d, (256, y), text, 32, (30, 32, 29))
save(im, 'counter_notice')
im = Image.new('RGB', (128, 192), (40, 62, 75)); d = ImageDraw.Draw(im)
label(d, (64, 24), 'PAGAMENTO', 12, (210, 223, 213)); label(d, (64, 66), 'R$ 18,00', 21, (222, 232, 214))
label(d, (64, 109), 'INSIRA OU', 12, (217, 227, 213)); label(d, (64, 135), 'APROXIME', 14, (217, 227, 213)); save(im, 'payment_screen')
im = Image.new('RGB', (256, 384), (212, 209, 192)); d = ImageDraw.Draw(im)
label(d, (128, 50), 'COPO TÉRMICO', 23, (38, 43, 36)); label(d, (128, 127), '44,99', 57, (156, 49, 37))
label(d, (128, 211), 'PORTA LATA', 26, (38, 43, 36)); label(d, (128, 282), '35,00', 53, (156, 49, 37)); save(im, 'cup_offer')
for index, base in enumerate([(36, 43, 43), (103, 67, 68), (88, 109, 90), (142, 123, 170), (198, 189, 163)]):
    im = Image.new('RGB', (128, 256), base); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 127, 20), fill=(44, 49, 46)); d.rectangle((0, 21, 127, 26), fill=(166, 176, 166))
    d.rectangle((25, 158, 104, 230), fill=(33, 42, 39)); label(d, (64, 184), 'TÉRMICO', 13, (219, 213, 188)); label(d, (64, 211), '500 ml', 11, (199, 206, 187))
    save(im, 'cup_' + str(index))
for index, base in enumerate([(154, 74, 123), (80, 135, 152), (184, 110, 52)]):
    im = Image.new('RGB', (128, 128), base); d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 127, 11), fill=(38, 40, 38)); d.rectangle((0, 44, 127, 93), fill=(219, 214, 189))
    label(d, (64, 62), 'VILA', 22, (49, 52, 45)); label(d, (64, 83), 'GIN • 750 ml', 10, (49, 52, 45))
    save(im, 'spirits_' + str(index))
im = Image.new('RGB', (256, 512), (215, 221, 212)); d = ImageDraw.Draw(im)
label(d, (128, 69), 'GELO', 54, (40, 111, 155)); label(d, (128, 136), 'EM CUBOS', 25, (40, 111, 155))
for x, y in [(45, 210), (131, 246), (77, 339)]:
    d.polygon([(x, y), (x+64, y-14), (x+78, y+43), (x+15, y+59)], fill=(155, 195, 212), outline=(77, 133, 169), width=3)
save(im, 'ice_freezer')
im = Image.new('RGB', (256, 256), (50, 58, 57)); d = ImageDraw.Draw(im)
for y in range(256):
    shade = 58 + int(math.sin(y*.034)*9); d.line((0, y, 255, y), fill=(shade-3, shade+3, shade+2))
label(d, (128, 219), 'SEM SINAL', 14, (86, 95, 90)); save(im, 'tv_screen')
im = Image.new('RGB', (128, 256), (190, 177, 142)); d = ImageDraw.Draw(im)
for y in range(256):
    for x in range(128):
        if rng.random() < .10: d.point((x, y), fill=(159, 146, 116))
label(d, (64, 62), 'CARVÃO', 23, (42, 42, 32)); label(d, (64, 102), 'VEGETAL', 15, (42, 42, 32)); label(d, (64, 185), '3 KG', 25, (42, 42, 32)); save(im, 'charcoal')
im = Image.new('RGBA', (128, 128)); d = ImageDraw.Draw(im)
for i in range(9):
    y = rng.randrange(8, 120); points = [(0, y)]
    for x in range(0, 129, 16): points.append((x, max(0, min(127, y+rng.randrange(-7, 8)))))
    d.line(points, fill=(43, 43, 35, 150), width=1)
save(im, 'cracks')
im = Image.new('RGBA', (256, 128)); px = im.load()
for y in range(128):
    for x in range(256):
        v = max(0, 1-((x-128)/124)**2-((y-64)/59)**2)
        px[x,y] = (38, 35, 24, int(v * rng.randrange(3, 28)))
save(im, 'floor_wear')

# Deterministic low-volume ambient cues. These are original synthesis, not samples.
audio = ROOT/'assets/audio'
for name, seconds in [('distant_traffic', 6.0), ('store_settle', 1.0)]:
    rate = 22050; output = bytearray(); low = 0.0
    for i in range(int(rate*seconds)):
        t=i/rate; low = low*.94 + rng.uniform(-1,1)*.06
        if name == 'distant_traffic':
            env=math.sin(math.pi*t/seconds)**2
            value=(low*.33 + math.sin(t*math.tau*(66+12*t/seconds))*.018)*env
        else:
            env=math.exp(-t*9); value=(low*.35+math.sin(t*math.tau*117)*.045)*env
        output.extend(struct.pack('<h', int(max(-1,min(1,value))*26000)))
    with wave.open(str(audio/(name+'.wav')), 'wb') as stream:
        stream.setnchannels(1); stream.setsampwidth(2); stream.setframerate(rate); stream.writeframes(output)
for metadata in OUT.glob('*.png.import'):
    metadata.write_text(metadata.read_text().replace('mipmaps/generate=false', 'mipmaps/generate=true'))
print('Original detail textures:', len(list(OUT.glob('*.png'))), '| ambient cues: 2')
