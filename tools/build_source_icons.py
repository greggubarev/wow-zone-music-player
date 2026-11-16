from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SIZE = 128
COLORS = ("#E7C878", "#D8B889", "#BED2EB", "#A6DAD5")
FONTS = (Path("C:/Windows/Fonts/arialbd.ttf"),
         Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"))


def font(size):
    for path in FONTS:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default(size=size)


def centered(draw, box, label, size, color):
    draw.text(((box[0] + box[2]) / 2, (box[1] + box[3]) / 2), label,
              font=font(size), fill=color, anchor="mm", stroke_width=1,
              stroke_fill="#0C1A20")


def build():
    canvas = Image.new("RGBA", (SIZE * 4, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    for index, color in enumerate(COLORS):
        x = index * SIZE
        draw.ellipse((x + 11, 11, x + 117, 117), fill="#10222B",
                     outline=color, width=6)
        draw.ellipse((x + 20, 20, x + 108, 108), outline=color, width=2)

    centered(draw, (0, 0, 128, 128), "PW", 51, COLORS[0])

    x = SIZE
    draw.polygon(((x + 64, 19), (x + 100, 45), (x + 90, 96),
                  (x + 64, 111), (x + 38, 96), (x + 28, 45)),
                 outline=COLORS[1], width=4)
    centered(draw, (x, 0, x + 128, 128), "III", 49, COLORS[1])

    x = SIZE * 2
    draw.line(((x + 28, 35), (x + 64, 18), (x + 100, 35)),
              fill=COLORS[2], width=5)
    draw.line(((x + 29, 94), (x + 64, 110), (x + 99, 94)),
              fill=COLORS[2], width=5)
    centered(draw, (x, 0, x + 128, 128), "L2", 54, COLORS[2])

    x = SIZE * 3
    for dx, color in ((43, COLORS[0]), (64, COLORS[1]), (85, COLORS[2])):
        draw.ellipse((x + dx - 10, 48, x + dx + 10, 68), fill=color)
    draw.line(((x + 45, 84), (x + 84, 84)), fill=COLORS[3], width=6)
    draw.polygon(((x + 78, 73), (x + 96, 84), (x + 78, 95)), fill=COLORS[3])

    atlas = canvas.resize((128, 32), Image.Resampling.LANCZOS)
    atlas.save(ROOT / "SourceIcons.tga", format="TGA", rle=False)


if __name__ == "__main__":
    build()
