# -*- coding: utf-8 -*-
"""Compose one GamePass card mock with REAL candy Luckiest Guy wordmarks (not CSS)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
COOL = Path(r"C:\Users\uka37\Downloads\COOLICONFORDROK")
FONT = COOL / "FIGMA_FONTS_Install_Me" / "LuckiestGuy-Regular.ttf"
PLATE = Path(r"C:\Users\uka37\Downloads\EXPORTfromFigma\GamePass card empty plate.png")
# Real GamePass icon (IconImageAssetId from Roblox product-info), not generic *icon
ICON = ROOT / "gp_icons" / "offhand.png"
CHIP_SVG = COOL / "GAMEPASS_CARDS" / "GamePass_PriceChip_A_Candy.svg"
GP_TITLE = COOL / "WORDMARKS_PureText" / "WORDMARK_GP_OFFHAND.png"
OUT = ROOT / "GamePass_SecondSword_CANDY.png"
OUT_OWNED = ROOT / "GamePass_SecondSword_CANDY_OWNED.png"
DOWNLOADS = Path(r"C:\Users\uka37\Downloads")
# From product-info (Second sword slot)
PRICE_TEXT = "R$ 249"
TITLE_TEXT = "SECOND SWORD SLOT"
DESC_TEXT = "UNLOCK OFFHAND WEAPON"


def lerp(a, b, t):
	return a + (b - a) * t


def rainbow(t: float):
	stops = [
		(0.0, (255, 255, 255)),
		(0.12, (220, 250, 255)),
		(0.26, (160, 235, 255)),
		(0.4, (200, 160, 255)),
		(0.54, (255, 130, 210)),
		(0.68, (255, 190, 100)),
		(0.82, (120, 240, 255)),
		(0.94, (255, 180, 240)),
		(1.0, (232, 210, 255)),
	]
	t = max(0.0, min(1.0, t))
	for i in range(len(stops) - 1):
		t0, c0 = stops[i]
		t1, c1 = stops[i + 1]
		if t0 <= t <= t1:
			u = (t - t0) / (t1 - t0) if t1 > t0 else 0
			return tuple(int(lerp(c0[j], c1[j], u)) for j in range(3))
	return stops[-1][1]


def gold_face(t: float, v: float):
	# gold candy for price / owned
	r, g, b = 255, 220, 90
	if v < 0.35:
		u = 1 - v / 0.35
		r = int(lerp(r, 255, u * 0.5))
		g = int(lerp(g, 255, u * 0.55))
		b = int(lerp(b, 220, u * 0.4))
	else:
		r, g, b = 255, int(lerp(200, 140, (v - 0.35) / 0.65)), 40
	return r, g, b


def green_face(t: float, v: float):
	r, g, b = 120, 255, 160
	if v < 0.35:
		u = 1 - v / 0.35
		r = int(lerp(r, 230, u * 0.5))
		g = int(lerp(g, 255, u * 0.3))
		b = int(lerp(b, 230, u * 0.4))
	return r, g, b


def render_one(text: str, font_size: int, palette: str = "rainbow") -> Image.Image:
	font = ImageFont.truetype(str(FONT), size=font_size)
	tmp = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
	td = ImageDraw.Draw(tmp)
	bb = td.textbbox((0, 0), text, font=font)
	tw, th = bb[2] - bb[0], bb[3] - bb[1]
	pad = max(48, font_size // 3)
	w, h = tw + pad * 2, th + pad * 2
	img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	tx = pad - bb[0]
	ty = pad - bb[1]

	glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	ImageDraw.Draw(glow).text((tx, ty), text, font=font, fill=(160, 80, 255, 170))
	glow = glow.filter(ImageFilter.GaussianBlur(16))
	img = Image.alpha_composite(img, glow)

	for i, col in enumerate(
		[
			(255, 140, 50, 255),
			(80, 230, 255, 255),
			(255, 90, 200, 255),
			(40, 20, 100, 255),
		]
	):
		off = 12 - i * 2
		layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
		ImageDraw.Draw(layer).text((tx + off, ty + off + 4), text, font=font, fill=col)
		img = Image.alpha_composite(img, layer)

	outline = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	od = ImageDraw.Draw(outline)
	rmax = max(8, font_size // 12)
	for dx in range(-rmax, rmax + 1):
		for dy in range(-rmax, rmax + 1):
			if dx * dx + dy * dy <= rmax * rmax:
				od.text((tx + dx, ty + dy), text, font=font, fill=(8, 10, 42, 255))
	img = Image.alpha_composite(img, outline)

	mask = Image.new("L", (w, h), 0)
	ImageDraw.Draw(mask).text((tx, ty), text, font=font, fill=255)
	face = Image.new("RGBA", (w, h), (0, 0, 0, 0))
	pix, m = face.load(), mask.load()
	for y in range(max(0, ty - 4), min(h, ty + th + 12)):
		for x in range(max(0, tx - 4), min(w, tx + tw + 12)):
			a = m[x, y]
			if a > 16:
				t = (x - tx) / max(1, tw)
				v = (y - ty) / max(1, th)
				if palette == "gold":
					r, g, b = gold_face(t, v)
				elif palette == "green":
					r, g, b = green_face(t, v)
				else:
					r, g, b = rainbow(t)
					if v < 0.34:
						u = 1 - v / 0.34
						r = int(lerp(r, 255, u * 0.62))
						g = int(lerp(g, 255, u * 0.62))
						b = int(lerp(b, 255, u * 0.62))
				pix[x, y] = (r, g, b, a)
	img = Image.alpha_composite(img, face)
	return img


def fit_w(im: Image.Image, max_w: int) -> Image.Image:
	if im.width <= max_w:
		return im
	h = int(im.height * (max_w / im.width))
	return im.resize((max_w, max(1, h)), Image.Resampling.LANCZOS)


def fit_box(im: Image.Image, max_w: int, max_h: int) -> Image.Image:
	"""Scale icon UP or down to fill box without stretch (keep aspect)."""
	if im.width <= 0 or im.height <= 0:
		return im
	r = min(max_w / im.width, max_h / im.height)
	nw = max(1, int(round(im.width * r)))
	nh = max(1, int(round(im.height * r)))
	return im.resize((nw, nh), Image.Resampling.LANCZOS)


def paste_c(base: Image.Image, layer: Image.Image, cx: int, cy: int):
	x = int(cx - layer.width / 2)
	y = int(cy - layer.height / 2)
	base.alpha_composite(layer, (x, y))


def load_chip(w: int, h: int) -> Image.Image:
	# SVG optional; fallback rounded candy pill
	try:
		import cairosvg  # type: ignore

		png = cairosvg.svg2png(url=str(CHIP_SVG), output_width=w, output_height=h)
		from io import BytesIO

		return Image.open(BytesIO(png)).convert("RGBA")
	except Exception:
		chip = Image.new("RGBA", (w, h), (0, 0, 0, 0))
		d = ImageDraw.Draw(chip)
		# outer glow
		for i in range(12, 0, -1):
			a = 18
			d.rounded_rectangle(
				[8 - i, 8 - i, w - 8 + i, h - 8 + i],
				radius=h // 2,
				outline=(180, 100, 255, a),
				width=3,
			)
		d.rounded_rectangle([6, 6, w - 6, h - 6], radius=h // 2, fill=(90, 40, 180, 255))
		d.rounded_rectangle([14, 14, w - 14, h - 14], radius=h // 2 - 6, fill=(140, 90, 255, 255))
		# top shine
		shine = Image.new("RGBA", (w, h), (0, 0, 0, 0))
		sd = ImageDraw.Draw(shine)
		sd.rounded_rectangle([22, 18, w - 22, h // 2], radius=h // 3, fill=(255, 255, 255, 70))
		chip = Image.alpha_composite(chip, shine)
		return chip


def compose(owned: bool = False) -> Image.Image:
	plate = Image.open(PLATE).convert("RGBA")
	# normalize to ~1920 wide for crispness
	target_w = 1600
	if plate.width != target_w:
		ratio = target_w / plate.width
		plate = plate.resize((target_w, int(plate.height * ratio)), Image.Resampling.LANCZOS)

	W, H = plate.size
	canvas = plate.copy()

	# LEFT: GamePass icon — BIG, natural aspect, NO squash into tiny square
	# Figma-style: icon owns most of the left half of the card face
	icon = Image.open(ICON).convert("RGBA")
	icon = fit_box(icon, max_w=int(W * 0.44), max_h=int(H * 0.78))
	# sit in left zone, a bit toward center so it meets the text
	paste_c(canvas, icon, int(W * 0.28), int(H * 0.52))

	# RIGHT panel
	px = int(W * 0.70)
	if GP_TITLE.exists():
		title = Image.open(GP_TITLE).convert("RGBA")
		title = fit_w(title, int(W * 0.40))
	else:
		title = fit_w(render_one(TITLE_TEXT, 92), int(W * 0.42))
	paste_c(canvas, title, px, int(H * 0.26))

	desc = fit_w(render_one(DESC_TEXT, 54), int(W * 0.38))
	paste_c(canvas, desc, px, int(H * 0.42))

	# Price chip — large candy button
	cw, ch = int(W * 0.44), int(H * 0.30)
	chip = load_chip(cw, ch)
	cx, cy = px, int(H * 0.74)
	paste_c(canvas, chip, cx, cy)

	if owned:
		price = fit_w(render_one("OWNED", 82, palette="green"), int(cw * 0.68))
	else:
		price = fit_w(render_one(PRICE_TEXT, 82, palette="gold"), int(cw * 0.74))
	paste_c(canvas, price, cx, cy)

	return canvas


def main():
	assert FONT.exists(), f"missing font {FONT}"
	assert PLATE.exists(), f"missing plate {PLATE}"
	assert ICON.exists(), f"missing icon {ICON}"

	img = compose(owned=False)
	img.save(OUT, "PNG")
	print("ok", OUT, img.size)

	owned = compose(owned=True)
	owned.save(OUT_OWNED, "PNG")
	print("ok", OUT_OWNED, owned.size)

	# easy access
	img.save(DOWNLOADS / "GamePass_SecondSword_CANDY.png", "PNG")
	owned.save(DOWNLOADS / "GamePass_SecondSword_CANDY_OWNED.png", "PNG")
	print("also -> Downloads")


if __name__ == "__main__":
	main()
