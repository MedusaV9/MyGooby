#!/usr/bin/env python3
"""Renders Gooby's app icon (Gooby/Assets.xcassets/AppIcon.appiconset/icon-1024.png).

Original artwork drawn in code: Gooby's head and upper body with the paws held together under the
chin, in front of a blurred cozy pink and peach room with shelves and a plant. The character
geometry (320-unit design box, origin in the center, y down) mirrors the SwiftUI rig in
Gooby/Features/Character/GoobyCharacterView.swift, so the icon and the app show the same Gooby.

    python3 -m venv .venv && .venv/bin/pip install pillow numpy
    .venv/bin/python Tools/render_app_icon.py Gooby/Assets.xcassets/AppIcon.appiconset/icon-1024.png
"""
import math
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# ---------------------------------------------------------------------------------------------
# Tiny vector renderer (Pillow + numpy) mimicking the SwiftUI primitives the rig uses.
# ---------------------------------------------------------------------------------------------
def hexc(h, a=1.0):
    h = h.lstrip('#')
    return (int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255, a)


class Grad:
    def __init__(self, rgb, al):
        self.rgb = rgb
        self.al = al


class Path:
    def __init__(self):
        self.pts = []
        self.subs = []

    def move(self, x, y):
        if self.pts:
            self.subs.append(self.pts)
        self.pts = [(x, y)]
        return self

    def line(self, x, y):
        self.pts.append((x, y))
        return self

    def curve(self, x, y, c1x, c1y, c2x, c2y, n=28):
        x0, y0 = self.pts[-1]
        for i in range(1, n + 1):
            t = i / n
            mt = 1 - t
            px = mt**3 * x0 + 3 * mt * mt * t * c1x + 3 * mt * t * t * c2x + t**3 * x
            py = mt**3 * y0 + 3 * mt * mt * t * c1y + 3 * mt * t * t * c2y + t**3 * y
            self.pts.append((px, py))
        return self

    def quad(self, x, y, cx, cy, n=24):
        x0, y0 = self.pts[-1]
        for i in range(1, n + 1):
            t = i / n
            mt = 1 - t
            self.pts.append((mt * mt * x0 + 2 * mt * t * cx + t * t * x, mt * mt * y0 + 2 * mt * t * cy + t * t * y))
        return self

    def polys(self):
        return self.subs + ([self.pts] if self.pts else [])


def ellipse(rect):
    x, y, w, h = rect
    p = Path()
    n = 72
    for i in range(n + 1):
        a = 2 * math.pi * i / n
        px = x + w / 2 + math.cos(a) * w / 2
        py = y + h / 2 + math.sin(a) * h / 2
        if i == 0:
            p.move(px, py)
        else:
            p.line(px, py)
    return p


def rrect(rect, r):
    x, y, w, h = rect
    r = min(r, w / 2, h / 2)
    p = Path()
    k = 0.5523 * r
    p.move(x + r, y)
    p.line(x + w - r, y)
    p.curve(x + w, y + r, x + w - r + k, y, x + w, y + r - k)
    p.line(x + w, y + h - r)
    p.curve(x + w - r, y + h, x + w, y + h - r + k, x + w - r + k, y + h)
    p.line(x + r, y + h)
    p.curve(x, y + h - r, x + r - k, y + h, x, y + h - r + k)
    p.line(x, y + r)
    p.curve(x + r, y, x, y + r - k, x + r - k, y)
    return p


def capsule(rect):
    x, y, w, h = rect
    return rrect(rect, min(w, h) / 2)


class Xf:
    """Affine transform: list of ops applied to design points."""

    def __init__(self, m=None):
        self.m = np.eye(3) if m is None else m

    def then(self, other):
        return Xf(other.m @ self.m)

    @staticmethod
    def rot(deg, ax=0, ay=0):
        a = math.radians(deg)
        c, s = math.cos(a), math.sin(a)
        t1 = np.array([[1, 0, -ax], [0, 1, -ay], [0, 0, 1]])
        r = np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])
        t2 = np.array([[1, 0, ax], [0, 1, ay], [0, 0, 1]])
        return Xf(t2 @ r @ t1)

    @staticmethod
    def scale(sx, sy, ax=0, ay=0):
        t1 = np.array([[1, 0, -ax], [0, 1, -ay], [0, 0, 1]])
        r = np.array([[sx, 0, 0], [0, sy, 0], [0, 0, 1]])
        t2 = np.array([[1, 0, ax], [0, 1, ay], [0, 0, 1]])
        return Xf(t2 @ r @ t1)

    @staticmethod
    def move(dx, dy):
        return Xf(np.array([[1, 0, dx], [0, 1, dy], [0, 0, 1]], dtype=float))

    def apply(self, pts):
        a = np.array([[x, y, 1] for x, y in pts]).T
        b = self.m @ a
        return list(zip(b[0], b[1]))


class Canvas:
    def __init__(self, px=960, box=320, ss=3, bg=None):
        self.px = px
        self.box = box
        self.ss = ss
        self.S = px * ss
        self.k = self.S / box
        self.rgb = np.zeros((self.S, self.S, 3))
        self.a = np.zeros((self.S, self.S))
        if bg is not None:
            self.rgb[:] = bg[:3]
            self.a[:] = 1
        yy, xx = np.mgrid[0:self.S, 0:self.S]
        self.X = (xx + 0.5) / self.k - box / 2
        self.Y = (yy + 0.5) / self.k - box / 2
        self.xf = Xf()
        self.clip = None

    def mask(self, path, xf=None):
        xf = (xf or Xf()).then(self.xf)
        img = Image.new('L', (self.S, self.S), 0)
        d = ImageDraw.Draw(img)
        for poly in path.polys():
            pts = [((x + self.box / 2) * self.k, (y + self.box / 2) * self.k) for x, y in xf.apply(poly)]
            if len(pts) > 2:
                d.polygon(pts, fill=255)
        m = np.asarray(img, dtype=float) / 255
        if self.clip is not None:
            m = m * self.clip
        return m

    def stroke_mask(self, path, width, xf=None, closed=True):
        xf = (xf or Xf()).then(self.xf)
        img = Image.new('L', (self.S, self.S), 0)
        d = ImageDraw.Draw(img)
        w = max(1, int(round(width * self.k)))
        for poly in path.polys():
            pts = [((x + self.box / 2) * self.k, (y + self.box / 2) * self.k) for x, y in xf.apply(poly)]
            if closed:
                pts = pts + [pts[0]]
            d.line(pts, fill=255, width=w, joint='curve')
            r = w / 2
            for (px, py) in (pts[0], pts[-1]):
                d.ellipse([px - r, py - r, px + r, py + r], fill=255)
        m = np.asarray(img, dtype=float) / 255
        if self.clip is not None:
            m = m * self.clip
        return m

    def paint(self, m, color):
        """color: (r,g,b,a) tuple or (rgb array, alpha array)."""
        if isinstance(color, Grad):
            rgb, al = color.rgb, color.al
            alpha = m * al
        else:
            rgb = np.array(color[:3])
            alpha = m * color[3]
        alpha = alpha[..., None] if alpha.ndim == 2 else alpha
        out_a = alpha[..., 0] + self.a * (1 - alpha[..., 0])
        num = rgb * alpha + self.rgb * (self.a[..., None]) * (1 - alpha)
        with np.errstate(invalid='ignore', divide='ignore'):
            self.rgb = np.where(out_a[..., None] > 0, num / np.maximum(out_a[..., None], 1e-9), 0)
        self.a = out_a

    def fill(self, path, color, xf=None):
        self.paint(self.mask(path, xf), color)

    def stroke(self, path, color, width, xf=None, closed=True):
        self.paint(self.stroke_mask(path, width, xf, closed), color)

    def soft(self, m, blur):
        img = Image.fromarray((m * 255).astype(np.uint8))
        img = img.filter(ImageFilter.GaussianBlur(blur * self.k))
        return np.asarray(img, dtype=float) / 255

    # gradients (in design coords, for a given rect; mimic SwiftUI EllipticalGradient)
    def elliptical(self, rect, stops, center=(0.5, 0.5), start=0.0, end=0.5, xf=None):
        x, y, w, h = rect
        X, Y = self.X, self.Y
        if xf is not None or self.xf is not None:
            full = (xf or Xf()).then(self.xf)
            inv = np.linalg.inv(full.m)
            X2 = inv[0, 0] * X + inv[0, 1] * Y + inv[0, 2]
            Y2 = inv[1, 0] * X + inv[1, 1] * Y + inv[1, 2]
            X, Y = X2, Y2
        cx = x + w * center[0]
        cy = y + h * center[1]
        d = np.sqrt(((X - cx) / w) ** 2 + ((Y - cy) / h) ** 2)
        t = np.clip((d - start) / max(1e-6, end - start), 0, 1)
        return self._stops(t, stops)

    def linear(self, rect, stops, p0=(0.5, 0), p1=(0.5, 1), xf=None):
        x, y, w, h = rect
        X, Y = self.X, self.Y
        full = (xf or Xf()).then(self.xf)
        inv = np.linalg.inv(full.m)
        X2 = inv[0, 0] * X + inv[0, 1] * Y + inv[0, 2]
        Y2 = inv[1, 0] * X + inv[1, 1] * Y + inv[1, 2]
        ax, ay = x + w * p0[0], y + h * p0[1]
        bx, by = x + w * p1[0], y + h * p1[1]
        dx, dy = bx - ax, by - ay
        t = np.clip(((X2 - ax) * dx + (Y2 - ay) * dy) / (dx * dx + dy * dy), 0, 1)
        return self._stops(t, stops)

    def _stops(self, t, stops):
        locs = [s[1] for s in stops]
        cols = [s[0] for s in stops]
        rgb = np.zeros(t.shape + (3,))
        al = np.zeros(t.shape)
        for c in range(4):
            vals = np.interp(t, locs, [col[c] for col in cols])
            if c < 3:
                rgb[..., c] = vals
            else:
                al = vals
        return Grad(rgb, al)

    def image(self):
        rgb = (np.clip(self.rgb, 0, 1) * 255).astype(np.uint8)
        a = (np.clip(self.a, 0, 1) * 255).astype(np.uint8)
        img = Image.fromarray(np.dstack([rgb, a]), 'RGBA')
        return img.resize((self.px, self.px), Image.LANCZOS)


# ---------------------------------------------------------------------------------------------
# Gooby (same shapes, colors and positions as the SwiftUI rig)
# ---------------------------------------------------------------------------------------------
FUR = dict(
    light=hexc('FFFBF3'), body=hexc('F8ECDA'), shade=hexc('EDD9BC'), edge=hexc('DDBF99'),
    inner=hexc('F6BCB8'), innerLight=hexc('FBD6D2'), cheek=hexc('F7A3A6'),
)
EYE = hexc('2B1D1B')
EYE_LOW = hexc('6A4639')
MOUTH = hexc('8E3546')
TONGUE = hexc('F4838F')
NOSE = hexc('EE8E9A')
NOSE_DARK = hexc('E07484')


def bun(rect, widest=0.58, top=0.6, side_up=0.56, side_down=0.6, bottom=0.7):
    x, y, w, h = rect
    my = y + h * widest
    up = h * widest
    lo = h - up
    p = Path()
    p.move(x + w / 2, y)
    p.curve(x + w, my, x + w / 2 + w / 2 * top, y, x + w, my - up * side_up)
    p.curve(x + w / 2, y + h, x + w, my + lo * side_down, x + w / 2 + w / 2 * bottom, y + h)
    p.curve(x, my, x + w / 2 - w / 2 * bottom, y + h, x, my + lo * side_down)
    p.curve(x + w / 2, y, x, my - up * side_up, x + w / 2 - w / 2 * top, y)
    return p


def ear_shape(rect):
    x, y, w, h = rect
    p = Path()
    p.move(x + w * 0.5, y)
    p.curve(x + w, y + h * 0.36, x + w * 0.86, y, x + w, y + h * 0.15)
    p.curve(x + w * 0.66, y + h, x + w, y + h * 0.62, x + w * 0.84, y + h * 0.9)
    p.line(x + w * 0.34, y + h)
    p.curve(x, y + h * 0.36, x + w * 0.16, y + h * 0.9, x, y + h * 0.62)
    p.curve(x + w * 0.5, y, x, y + h * 0.15, x + w * 0.14, y)
    return p


def tuft_shape(rect, lean=0.0):
    """GoobyTuftShape: a soft lock with a rounded tip curling to the right."""
    x, y, w, h = rect
    p = Path()
    p.move(x, y + h)
    p.curve(x + w * 0.72, y, x, y + h * 0.4, x + w * 0.3, y)
    p.curve(x + w, y + h, x + w * 1.02, y, x + w, y + h * 0.5)
    p.quad(x, y + h, x + w / 2, y + h * 1.1)
    return p


def mouth_shape(rect):
    x, y, w, h = rect
    p = Path()
    p.move(x, y)
    p.quad(x + w, y, x + w / 2, y + h * 0.16)
    p.curve(x + w / 2, y + h, x + w, y + h * 0.6, x + w * 0.8, y + h)
    p.curve(x, y, x + w * 0.2, y + h, x, y + h * 0.6)
    return p


def nose_shape(rect):
    x, y, w, h = rect
    p = Path()
    p.move(x, y + h * 0.32)
    p.curve(x + w, y + h * 0.32, x + w * 0.08, y - h * 0.1, x + w * 0.92, y - h * 0.1)
    p.curve(x + w * 0.5, y + h, x + w, y + h * 0.66, x + w * 0.64, y + h)
    p.curve(x, y + h * 0.32, x + w * 0.36, y + h, x, y + h * 0.66)
    return p


def arc_up(rect):
    """'^' happy eye."""
    x, y, w, h = rect
    p = Path()
    p.move(x, y + h)
    p.quad(x + w, y + h, x + w / 2, y - h)
    return p


def fur_part(c, path, rect, fur, xf=None, center=(0.36, 0.28), outline=2.4, reach=0.78):
    """Plush fill: soft radial light, shade toward the far edge, tonal outline."""
    m = c.mask(path, xf)
    c.paint(m, c.elliptical(rect, [(fur['light'], 0), (fur['body'], 0.45), (fur['shade'], 1)], center=center, end=reach, xf=xf))
    if outline:
        c.stroke(path, fur['edge'], outline, xf)


def head(c, fur, pose):
    rect = (-103, -76, 206, 164)
    path = bun(rect)
    fur_part(c, path, rect, fur, center=(0.4, 0.3), reach=0.82, outline=0)
    # cheeks, clipped to the head
    clip = c.mask(path)
    old = c.clip
    c.clip = clip
    for sx in (-1, 1):
        r = (sx * 70 - 30, 44 - 18, 60, 36)
        c.fill(ellipse(r), c.elliptical(r, [(fur['cheek'][:3] + (0.85,), 0), (fur['cheek'][:3] + (0.55,), 0.5), (fur['cheek'][:3] + (0.0,), 1)], end=0.5))
    c.clip = old
    # sheen top-left
    r = (-80, -62, 70, 36)
    xf = Xf.rot(-20, -45, -44)
    c.fill(ellipse(r), c.elliptical(r, [(hexc('FFFFFF', 0.75), 0), (hexc('FFFFFF', 0), 1)], end=0.5, xf=xf), xf)
    c.stroke(path, fur['edge'], 2.4)


TUFTS = [(-8, -92, 13, 18, -24, 0), (0, -96, 14, 22, 2, 0), (8, -91, 12, 16, 30, 0)]


def tuft(c, fur):
    for (x, y, w, h, rot, lean) in TUFTS:
        rect = (x - w / 2, y, w, h)
        xf = Xf.rot(rot, x, y + h)
        fur_part(c, tuft_shape(rect, lean), rect, fur, xf=xf, outline=2.0)


def ears(c, fur, pose, length=118):
    for sx in (-1, 1):
        w = 58
        bx = sx * 42
        by = -34
        rect = (bx - w / 2, by - length, w, length)
        angle = sx * (9 + pose.get('ear', 0))
        xf = Xf.rot(angle, bx, by)
        path = ear_shape(rect)
        fur_part(c, path, rect, fur, xf=xf, center=(0.5 - sx * 0.14, 0.2), reach=0.9)
        # inner ear
        ir = (bx - w * 0.29, by - length * 0.88, w * 0.58, length * 0.8)
        ip = ear_shape(ir)
        c.fill(ip, c.linear(ir, [(fur['innerLight'], 0), (fur['inner'], 0.55), (fur['inner'], 1)], xf=xf), xf)


def body(c, fur):
    rect = (-90, 24, 180, 128)
    path = bun(rect, widest=0.6, top=0.6, side_up=0.6, side_down=0.6, bottom=0.6)
    fur_part(c, path, rect, fur, center=(0.42, 0.2), reach=0.8)
    r = (-50, 84, 100, 60)
    c.fill(ellipse(r), c.elliptical(r, [(hexc('FFFFFF', 0.55), 0), (hexc('FFFFFF', 0), 1)], end=0.5))


def feet(c, fur):
    for sx in (-1, 1):
        cx, cy = sx * 44, 138
        rect = (cx - 30, cy - 17, 60, 34)
        fur_part(c, ellipse(rect), rect, fur, center=(0.4, 0.25))
        c.fill(ellipse((cx - 12, cy - 3, 24, 15)), fur['inner'])
        for i, dx in enumerate((-10, 0, 10)):
            dy = -9 if i != 1 else -11
            c.fill(ellipse((cx + dx - 3.6, cy + dy - 3.6, 7.2, 7.2)), fur['inner'])


def arms(c, fur, pose):
    for sx in (-1, 1):
        shoulder = (sx * (70 - pose.get('arm', 0) * 14), 76)
        w, h = 30, 46
        rect = (shoulder[0] - w / 2, shoulder[1], w, h)
        angle = sx * (50 + pose.get('arm', 0) * 22 - pose.get('raise', 0) * 176)
        xf = Xf.rot(angle, shoulder[0], shoulder[1])
        fur_part(c, capsule(rect), rect, fur, xf=xf, center=(0.4, 0.3), outline=2.2)


def neck_shade(c, fur):
    r = (-80, 75, 160, 30)
    c.fill(ellipse(r), c.elliptical(r, [(fur['shade'][:3] + (0.9,), 0), (fur['shade'][:3] + (0,), 1)], end=0.5))


def eyes(c, pose):
    kind = pose.get('eyes', 'open')
    for sx in (-1, 1):
        cx, cy = sx * 46, 16
        if kind == 'happy':
            r = (cx - 17, cy - 6, 34, 14)
            c.stroke(arc_up(r), EYE, 6.5, closed=False)
            continue
        w, h = 46, 52
        r = (cx - w / 2, cy - h / 2, w, h)
        c.fill(ellipse(r), c.elliptical(r, [(EYE_LOW, 0), (EYE, 0.62), (EYE, 1)], center=(0.5, 0.92), end=0.85))
        c.fill(ellipse((cx - 8 - 9.5, cy - 12 - 9.5, 19, 19)), hexc('FFFFFF'))
        c.fill(ellipse((cx + 10 - 4.2, cy + 10 - 4.2, 8.4, 8.4)), hexc('FFFFFF', 0.95))


def nose(c):
    r = (-7.5, 31, 15, 10)
    c.fill(nose_shape(r), c.linear(r, [(hexc('F6A2AE'), 0), (NOSE_DARK, 1)]))
    c.fill(ellipse((-4.5, 32, 5, 3)), hexc('FFFFFF', 0.8))


def mouth(c, pose):
    kind = pose.get('mouth', 'smile')
    if kind == 'smile':
        w, h = 26, 17
    else:
        w, h = 34, 23
    r = (-w / 2, 44, w, h)
    p = mouth_shape(r)
    m = c.mask(p)
    c.paint(m, MOUTH)
    old = c.clip
    c.clip = m
    tr = (-w * 0.34, 44 + h * 0.45, w * 0.68, h * 0.8)
    c.fill(ellipse(tr), TONGUE)
    c.clip = old


def shadow(c):
    r = (-100, 136, 200, 30)
    c.fill(ellipse(r), c.elliptical(r, [(hexc('3D3656', 0.22), 0), (hexc('3D3656', 0), 1)], end=0.5))


def gooby(c, pose=None):
    pose = pose or {}
    fur = FUR
    shadow(c)
    ears(c, fur, pose)
    body(c, fur)
    feet(c, fur)
    arms(c, fur, pose)
    neck_shade(c, fur)
    tuft(c, fur)
    head(c, fur, pose)
    eyes(c, pose)
    nose(c)
    mouth(c, pose)


# ---------------------------------------------------------------------------------------------
# Icon composition
# ---------------------------------------------------------------------------------------------
PX = 1024


def room():
    """Blurred cozy room: peach wall, a shelf with pots and books, a plant, warm bokeh."""
    c = Canvas(px=PX, box=320, ss=1, bg=hexc('F8CFC4'))
    wall = (-160, -160, 320, 320)
    c.fill(rrect(wall, 0), c.linear(wall, [(hexc('FBDCCF'), 0), (hexc('F6C2B8'), 0.6), (hexc('EFA9A4'), 1)]))
    # window light top-left
    r = (-190, -210, 260, 230)
    c.fill(ellipse(r), c.elliptical(r, [(hexc('FFF3E6', 0.85), 0), (hexc('FFF3E6', 0), 1)], end=0.5))
    # shelf left
    c.fill(rrect((-170, -40, 130, 12), 5), hexc('E39C8E'))
    c.fill(rrect((-150, -86, 26, 46), 6), hexc('FFF1E4'))
    c.fill(rrect((-118, -76, 14, 36), 3), hexc('B9A4E0'))
    c.fill(rrect((-102, -72, 12, 32), 3), hexc('8EC6D8'))
    c.fill(rrect((-88, -80, 13, 40), 3), hexc('F7D27A'))
    c.fill(ellipse((-148, -110, 22, 28)), hexc('8CC08A'))
    # second shelf
    c.fill(rrect((-170, 40, 110, 12), 5), hexc('E39C8E'))
    c.fill(rrect((-150, 4, 30, 36), 8), hexc('F5E6D8'))
    c.fill(ellipse((-145, -14, 22, 24)), hexc('79B37E'))
    # plant right: pot + leaves
    c.fill(rrect((96, 70, 56, 60), 12), hexc('F7E8DA'))
    for (x, y, w, h, rot, col) in [(110, -10, 34, 90, -24, '6FAE78'), (126, -30, 30, 100, 8, '82BE84'),
                                   (140, 0, 30, 84, 34, '5E9F6C'), (98, 20, 26, 64, -48, '8CC88C'),
                                   (150, 30, 26, 60, 52, '74B37B')]:
        rect = (x - w / 2, y, w, h)
        c.fill(ellipse(rect), hexc(col), Xf.rot(rot, x, y + h))
    # bokeh
    for (x, y, d, a) in [(70, -120, 40, 0.5), (120, -70, 26, 0.45), (-40, -140, 30, 0.35), (30, -90, 18, 0.4), (150, -130, 34, 0.4)]:
        c.fill(ellipse((x - d / 2, y - d / 2, d, d)), hexc('FFF7EC', a))
    return c.image().filter(ImageFilter.GaussianBlur(26))


def gooby_layer():
    box = 276
    c = Canvas(px=PX, box=box, ss=2)
    c.xf = Xf.move(0, 14)
    pose = {'mouth': 'laugh', 'arm': 0.6}
    fur = FUR
    ears(c, fur, pose, length=118 * 0.96)
    body(c, fur)
    arms(c, fur, pose)
    neck_shade(c, fur)
    tuft(c, fur)
    head(c, fur, pose)
    eyes(c, pose)
    nose(c)
    mouth(c, pose)
    # two little paws held up together under the chin
    for sx in (-1, 1):
        r = (sx * 21 - 19, 84, 38, 32)
        fur_part(c, ellipse(r), r, fur, center=(0.4, 0.25), reach=0.8, outline=2.4)
        for dx in (-5, 5):
            p = Path().move(sx * 21 + dx, 86).quad(sx * 21 + dx, 93, sx * 21 + dx * 1.15, 89.5)
            c.stroke(p, fur['edge'], 2.0, closed=False)
    return c.image()


def main(out):
    bg = room().convert('RGBA')
    fig = gooby_layer()
    # soft shadow from the figure's alpha
    alpha = fig.split()[-1]
    shadow = Image.new('RGBA', fig.size, (150, 70, 70, 0))
    shadow.putalpha(alpha.point(lambda v: int(v * 0.28)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    bg.alpha_composite(shadow, (10, 22))
    bg.alpha_composite(fig)
    bg.convert('RGB').save(out)
    print('saved', out)


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'icon.png')
