from PIL import Image

SRC = r'd:/aya/assets/icons/MonUnivers1.PNG'
BG = (54, 114, 63, 255)  # vert du logo #36723F

logo = Image.open(SRC).convert('RGBA')

SIZE = 1024

# Foreground adaptatif : fond vert plein + logo centre a ~66% (zone de securite)
fg = Image.new('RGBA', (SIZE, SIZE), BG)
scale = 0.66
w = int(SIZE * scale)
resized = logo.resize((w, w), Image.LANCZOS)
off = (SIZE - w) // 2
fg.paste(resized, (off, off), resized)
fg.save(r'd:/aya/assets/icons/MonUnivers_fg.png')

# Icone legacy (carre/arrondi) : logo plus grand ~86% sur fond vert
legacy = Image.new('RGBA', (SIZE, SIZE), BG)
scale2 = 0.86
w2 = int(SIZE * scale2)
resized2 = logo.resize((w2, w2), Image.LANCZOS)
off2 = (SIZE - w2) // 2
legacy.paste(resized2, (off2, off2), resized2)
legacy.save(r'd:/aya/assets/icons/MonUnivers_legacy.png')

print('OK icons generated')
