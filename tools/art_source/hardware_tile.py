"""Key a hardware illustration (white or checkerboard background) to alpha and tile it at 512.

    python3 tools/art_source/hardware_tile.py SRC.png DST.png [--level]
Only background connected to the frame edge is removed, so white panels inside the vehicle
survive. Pale grey blobs that are not part of the vehicle (painted floor shadows, seed-edge
slivers) are dropped. --level rotates a long diagonal object horizontal, narrow end left.
"""
import sys, math
import numpy as np, cv2
from PIL import Image

def key(src: Image.Image) -> Image.Image:
    im = np.asarray(src.convert("RGB")).astype(int); mx = im.max(2); mn = im.min(2)
    bgcol = (mx - mn < 14) & (mn > 188)                       # white or checker grey
    bgcol = cv2.morphologyEx(bgcol.astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    n, lab, st, _ = cv2.connectedComponentsWithStats(bgcol); bg = np.zeros_like(bgcol)
    H, W = bgcol.shape
    for i in range(1, n):
        x, y, w, h, a = st[i]
        if x == 0 or y == 0 or x + w == W or y + h == H: bg[lab == i] = 1
    alpha = np.where(bg > 0, 0, 255).astype(np.uint8)
    rim = (cv2.dilate(bg, np.ones((3, 3), np.uint8)) > 0) & (bg == 0)   # anti-aliased edge: half alpha, keeps thin lines
    alpha[rim] = 150
    # floor shadows: flat pale-grey (not white) pixels in the lower half of the subject
    ys, xs = np.nonzero(alpha); cy = (ys.min() + ys.max()) / 2
    pale = (mx - mn < 14) & (mn > 170) & (alpha > 0)
    pale[: int(cy + 0.2 * (ys.max() - cy))] = False                     # only the lowest part of the subject
    n, lab, st, _ = cv2.connectedComponentsWithStats(pale.astype(np.uint8))
    for i in range(1, n):
        x, y, w, h, a = st[i]
        if a > 300 and w > 3 * h: alpha[lab == i] = 0
    # detached slivers (seed-edge lines) and detached pale blobs
    n, lab, st, _ = cv2.connectedComponentsWithStats((alpha > 0).astype(np.uint8))
    if n > 2:
        main = 1 + np.argmax(st[1:, 4])
        for i in range(1, n):
            if i == main: continue
            x, y, w, h, a = st[i]; comp = lab == i; px = im[comp]
            palefrac = ((px.max(1) - px.min(1) < 16) & (px.min(1) > 170)).mean()
            mx0, my0, mw, mh = st[main][:4]
            far = x + w < mx0 - 30 or x > mx0 + mw + 30 or y + h < my0 - 30 or y > my0 + mh + 30
            if palefrac > 0.7 or (h > 60 and w < 6) or (w > 60 and h < 6) or (far and a < 400): alpha[comp] = 0
    return Image.fromarray(np.dstack([im.astype(np.uint8), alpha]), "RGBA")

def level(out: Image.Image) -> Image.Image:
    A = np.asarray(out)[..., 3] > 0; ys, xs = np.nonzero(A); cov = np.cov(np.stack([xs, ys])); w, v = np.linalg.eigh(cov); ax = v[:, 1]
    out = out.rotate(math.degrees(math.atan2(ax[1], ax[0])), resample=Image.BICUBIC, expand=True)
    A = np.asarray(out)[..., 3] > 0; cols = A.sum(0); nz = np.nonzero(cols)[0]
    return out.transpose(Image.FLIP_LEFT_RIGHT) if cols[nz[:30]].mean() > cols[nz[-30:]].mean() else out

def tile(out: Image.Image) -> Image.Image:
    bb = out.getchannel("A").getbbox(); out = out.crop(bb); sc = min(480 / out.width, 480 / out.height)
    out = out.resize((max(1, int(out.width * sc)), max(1, int(out.height * sc))), Image.LANCZOS)
    t = Image.new("RGBA", (512, 512), (0, 0, 0, 0)); t.paste(out, ((512 - out.width) // 2, (512 - out.height) // 2)); return t

if __name__ == "__main__":
    out = key(Image.open(sys.argv[1]))
    if "--level" in sys.argv: out = level(out)
    tile(out).save(sys.argv[2])
