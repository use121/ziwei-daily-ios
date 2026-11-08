#!/usr/bin/env python3
"""生成 App 图标候选（1024×1024，无 alpha）。

风格跟 App 内一致：宣纸底 / 朱砂 / 描金。
全部用 4 倍超采样绘制再缩回 1024，保证边缘干净没有锯齿。
"""

import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 4096          # 绘制尺寸（4x）
OUT = 1024        # 最终尺寸

CINNABAR = (176, 42, 34)
CINNABAR_DEEP = (122, 24, 19)
GOLD = (226, 196, 146)
GOLD_DEEP = (198, 158, 96)
PAPER = (247, 241, 227)
INK = (58, 40, 32)

SONGTI = "/System/Library/Fonts/Supplemental/Songti.ttc"


def radial_gradient(size, inner, outer, power=0.85):
    """中心亮、边缘暗的径向渐变。"""
    y, x = np.mgrid[0:size, 0:size]
    cx = cy = size / 2
    r = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / (size * 0.72)
    r = np.clip(r, 0, 1) ** power
    arr = np.zeros((size, size, 3), dtype=np.float32)
    for i in range(3):
        arr[:, :, i] = inner[i] + (outer[i] - inner[i]) * r
    return arr


def add_grain(arr, amount=3.0, seed=7):
    rng = np.random.default_rng(seed)
    noise = rng.normal(0, amount, (arr.shape[0], arr.shape[1], 1))
    return np.clip(arr + noise, 0, 255)


def to_image(arr):
    return Image.fromarray(arr.astype(np.uint8), "RGB")


def star_points(cx, cy, long_r, short_r, tips=8, rot=-math.pi / 2):
    """星形多边形顶点。tips=4 是四芒星，8 是八芒星。"""
    pts = []
    for i in range(tips * 2):
        ang = rot + i * math.pi / tips
        r = long_r if i % 2 == 0 else short_r
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    return pts


def draw_ring(d, cx, cy, r, width, color, alpha=255):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=color + (alpha,), width=width)


def glow(layer, radius):
    """给单独一层做外发光。"""
    blurred = layer.filter(ImageFilter.GaussianBlur(radius))
    return rendered_glow(blurred)


def rendered_glow(img):
    return img


def finish(img):
    return img.resize((OUT, OUT), Image.LANCZOS)


def square_points(cx, cy, half, rot=0.0):
    return [
        (cx + half * math.cos(rot + i * math.pi / 2) * math.sqrt(2) / math.sqrt(2) * 1.0,
         cy + half * math.sin(rot + i * math.pi / 2) * 1.0)
        for i in range(4)
    ]


def octagram(d, cx, cy, half, fill):
    """传统八角星纹：两个正方形叠转 45°。"""
    for rot in (math.pi / 4, 0.0):
        pts = []
        for i in range(4):
            ang = rot + i * math.pi / 2 + math.pi / 4
            pts.append((cx + half * math.cos(ang), cy + half * math.sin(ang)))
        d.polygon(pts, fill=fill)


# ---------------------------------------------------------------- A 星盘
def design_a():
    base = add_grain(radial_gradient(S, (192, 52, 43), (92, 17, 13), 1.05), 2.4)
    img = to_image(base).convert("RGBA")

    halo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    draw_ring(hd, S / 2, S / 2, 1600, 34, GOLD)
    halo = halo.filter(ImageFilter.GaussianBlur(26))
    img = Image.alpha_composite(img, halo)

    d = ImageDraw.Draw(img)
    draw_ring(d, S / 2, S / 2, 1600, 22, GOLD, 255)
    draw_ring(d, S / 2, S / 2, 1400, 5, GOLD, 80)

    for i in range(12):
        ang = -math.pi / 2 + i * math.pi / 6
        x1, y1 = S / 2 + 1490 * math.cos(ang), S / 2 + 1490 * math.sin(ang)
        x2, y2 = S / 2 + 1710 * math.cos(ang), S / 2 + 1710 * math.sin(ang)
        d.line([x1, y1, x2, y2], fill=GOLD + (235,), width=16)

    # 中心八角星纹
    star = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(star)
    octagram(sd, S / 2, S / 2, 840, GOLD + (255,))
    bloom = star.filter(ImageFilter.GaussianBlur(70))
    img = Image.alpha_composite(img, bloom)
    img = Image.alpha_composite(img, star)

    d = ImageDraw.Draw(img)
    d.ellipse([S / 2 - 66, S / 2 - 66, S / 2 + 66, S / 2 + 66], fill=(146, 32, 25, 255))
    return finish(img.convert("RGB"))


# ---------------------------------------------------------------- B 罗盘（宣纸）
def design_b():
    base = add_grain(radial_gradient(S, (253, 249, 240), (232, 220, 198), 1.2), 3.0)
    img = to_image(base).convert("RGBA")
    d = ImageDraw.Draw(img)

    cx = cy = S / 2
    # 单一朱砂主环，干净
    draw_ring(d, cx, cy, 1520, 54, CINNABAR)
    # 外侧一条极细金线，作为收边
    draw_ring(d, cx, cy, 1628, 10, GOLD_DEEP, 150)

    # 十二宫：跨越主环的短刻度
    for i in range(12):
        ang = -math.pi / 2 + i * math.pi / 6
        x1, y1 = cx + 1410 * math.cos(ang), cy + 1410 * math.sin(ang)
        x2, y2 = cx + 1630 * math.cos(ang), cy + 1630 * math.sin(ang)
        d.line([x1, y1, x2, y2], fill=CINNABAR + (255,), width=34)

    # 中心四芒星
    d.polygon(star_points(cx, cy, 760, 268, tips=4), fill=CINNABAR + (255,))
    d.ellipse([cx - 58, cy - 58, cx + 58, cy + 58], fill=(250, 244, 232, 255))
    d.ellipse([cx - 30, cy - 30, cx + 30, cy + 30], fill=CINNABAR + (255,))
    return finish(img.convert("RGB"))


# ---------------------------------------------------------------- C 字标
def design_c():
    base = add_grain(radial_gradient(S, (190, 48, 40), (104, 20, 16), 1.0), 2.2)
    img = to_image(base).convert("RGBA")
    d = ImageDraw.Draw(img)

    # 极淡内框，只做收边，不抢字
    inset = 210
    d.rounded_rectangle([inset, inset, S - inset, S - inset], radius=70,
                        outline=GOLD + (70,), width=9)

    font = ImageFont.truetype(SONGTI, 1180)
    text = "紫微"
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    bbox = ld.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    ld.text(((S - tw) / 2 - bbox[0], (S - th) / 2 - bbox[1] - 120), text, font=font, fill=GOLD + (255,))
    bloom = layer.filter(ImageFilter.GaussianBlur(28))
    img = Image.alpha_composite(img, bloom)
    img = Image.alpha_composite(img, layer)

    d = ImageDraw.Draw(img)
    f2 = ImageFont.truetype(SONGTI, 118)
    sub = "Z I W E I"
    sb = d.textbbox((0, 0), sub, font=f2)
    d.text(((S - (sb[2] - sb[0])) / 2 - sb[0], S - 620), sub, font=f2, fill=GOLD + (165,))
    return finish(img.convert("RGB"))


def contact_sheet(images, path, tile=440, gap=34, bg=(26, 22, 20)):
    """每个方案一列：大图 + 桌面尺寸(120px) + 通知尺寸(60px)。"""
    cols = len(images)
    label_h = 96
    w = cols * tile + gap * (cols + 1)
    h = gap + tile + 140 + label_h + gap
    sheet = Image.new("RGB", (w, h), bg)
    for i, im in enumerate(images):
        x = gap + i * (tile + gap)
        y = gap
        sheet.paste(im.resize((tile, tile), Image.LANCZOS), (x, y))
        # 真实尺寸：120px（桌面 60pt@2x）与 60px（列表/通知）
        small_y = y + tile + 34
        sheet.paste(im.resize((120, 120), Image.LANCZOS), (x + 20, small_y))
        sheet.paste(im.resize((60, 60), Image.LANCZOS), (x + 168, small_y + 30))
        tag = ["A 星盘", "B 罗盘", "C 字标", "D 星+字"][i] if i < 4 else f"#{i}"
        ImageDraw.Draw(sheet).text((x + 4, small_y + 132), tag,
                                   fill=(210, 200, 190), font=ImageFont.truetype(SONGTI, 40))
    sheet.save(path)


# ---------------------------------------------------------------- D 星纹 + 字标
def design_d():
    base = add_grain(radial_gradient(S, (190, 48, 40), (100, 19, 15), 1.0), 2.2)
    img = to_image(base).convert("RGBA")

    # 上方八角星纹
    star = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(star)
    octagram(sd, S / 2, 1330, 400, GOLD + (255,))
    bloom = star.filter(ImageFilter.GaussianBlur(40))
    img = Image.alpha_composite(img, bloom)
    img = Image.alpha_composite(img, star)

    d = ImageDraw.Draw(img)
    d.ellipse([S / 2 - 52, 1278, S / 2 + 52, 1382], fill=(146, 32, 25, 255))

    # 下方紫微二字
    font = ImageFont.truetype(SONGTI, 620)
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    text = "紫微"
    bbox = ld.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    ld.text(((S - tw) / 2 - bbox[0], 2060 - bbox[1]), text, font=font, fill=GOLD + (255,))
    img = Image.alpha_composite(img, layer.filter(ImageFilter.GaussianBlur(22)))
    img = Image.alpha_composite(img, layer)

    d = ImageDraw.Draw(img)
    f2 = ImageFont.truetype(SONGTI, 110)
    sub = "Z I W E I  D A I L Y"
    sb = d.textbbox((0, 0), sub, font=f2)
    d.text(((S - (sb[2] - sb[0])) / 2 - sb[0], 2900), sub, font=f2, fill=GOLD + (150,))
    return finish(img.convert("RGB"))


if __name__ == "__main__":
    out_dir = os.path.dirname(os.path.abspath(__file__)) + "/icon-candidates"
    os.makedirs(out_dir, exist_ok=True)
    a = design_a()
    b = design_b()
    c = design_c()
    e = design_d()
    for name, im in (("icon-a.png", a), ("icon-b.png", b), ("icon-c.png", c), ("icon-d.png", e)):
        im.save(f"{out_dir}/{name}")
    contact_sheet([a, b, c, e], f"{out_dir}/compare.png")
    for name in ("icon-a.png", "icon-b.png", "icon-c.png", "icon-d.png"):
        print(name, os.path.getsize(f"{out_dir}/{name}"), "bytes")


# ---------------------------------------------------------------- 最终稿：B 宣纸罗盘
def design_b_final(tone="light"):
    """tone: light（默认）/ dark / tinted"""
    if tone == "light":
        # 渐变只留极轻的一层：大跨度渐变会让 PNG 无法压缩，1024 图标会飙到 800KB
        bg_in, bg_out = (252, 249, 241), (246, 240, 228)
        ring, star_c, gold_line = CINNABAR, CINNABAR, GOLD_DEEP
        gold_alpha, hole = 205, (250, 244, 232)
    elif tone == "dark":
        bg_in, bg_out = (36, 30, 26), (24, 20, 18)
        ring, star_c = (198, 62, 48), (206, 70, 55)
        gold_line, gold_alpha, hole = (206, 168, 112), 120, (30, 23, 21)
    else:  # tinted：灰度，交给系统上色
        bg_in, bg_out = (255, 255, 255), (242, 242, 242)
        ring, star_c = (96, 96, 96), (72, 72, 72)
        gold_line, gold_alpha, hole = (168, 168, 168), 255, (255, 255, 255)

    # 不加纸纹噪点：噪点会让 PNG 几乎无法压缩（单张从 125KB 涨到 575KB），
    # 而图标在 60pt 下根本看不到这层纹理
    base = radial_gradient(S, bg_in, bg_out, 1.2)
    img = to_image(base).convert("RGBA")
    d = ImageDraw.Draw(img)
    cx = cy = S / 2

    # 外圈细线收边
    draw_ring(d, cx, cy, 1640, 13, gold_line, gold_alpha)
    # 朱砂主环
    draw_ring(d, cx, cy, 1500, 92, ring)
    # 十二宫刻度：跨环短线
    for i in range(12):
        ang = -math.pi / 2 + i * math.pi / 6
        x1, y1 = cx + 1350 * math.cos(ang), cy + 1350 * math.sin(ang)
        x2, y2 = cx + 1652 * math.cos(ang), cy + 1652 * math.sin(ang)
        d.line([x1, y1, x2, y2], fill=ring + (255,), width=46)

    # 中心四芒星
    d.polygon(star_points(cx, cy, 752, 300, tips=4), fill=star_c + (255,))

    # 天池：星心的同心圆，比白点更接近罗盘语汇
    d.ellipse([cx - 140, cy - 140, cx + 140, cy + 140], fill=hole + (255,))
    draw_ring(d, cx, cy, 116, 26, ring)
    d.ellipse([cx - 36, cy - 36, cx + 36, cy + 36], fill=ring + (255,))
    return finish(img.convert("RGB"))
