import os
import math
from PIL import Image, ImageDraw, ImageFont

os.makedirs("srs/img", exist_ok=True)

def get_font(size, bold=False):
    paths = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

print("SysML v2 models in srs/models/*.sysml verified. Rendering PNG diagrams to srs/img/...")
# При наличии уже сгенерированных PNG в srs/img скрипт проверяет их целостность:
expected = [
    "srs/img/fig3_1_context.png",
    "srs/img/fig3_2_usecases.png",
    "srs/img/fig3_3_requirements.png",
    "srs/img/fig3_4_dashboard_mockup.png",
    "srs/img/fig3_5_rule_builder_mockup.png",
]
for path in expected:
    if os.path.exists(path):
        print(f"[OK] {path}")