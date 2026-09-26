from __future__ import annotations

from pathlib import Path
from statistics import median
from typing import Iterable

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs" / "sentinel_sources"
OUTPUT = ROOT / "assets" / "bosses" / "sentinel"
OUTPUT.mkdir(parents=True, exist_ok=True)

CELL_W = 256
CELL_H = 192
ANCHOR_X = 128
GROUND_Y = 172
TARGET_BODY_HEIGHT = 106.0

SPECS = {
    "idle_core": ("sentinel_idle_core_source.png", 4, 2, list(range(8))),
    "walk": ("sentinel_walk_source.png", 3, 2, list(range(6))),
    "hit": ("sentinel_hit_source.png", 2, 1, [0, 1]),
    "shoot": ("sentinel_shoot_source.png", 4, 1, [0, 1, 2, 3]),
    "vertical_attack": ("sentinel_vertical_attack_source.png", 4, 1, [0, 1, 2, 3]),
    "phase_transition": ("sentinel_phase_transition_source.png", 5, 1, [0, 1, 2, 3, 4]),
    "death": ("sentinel_death_source.png", 6, 1, [0, 1, 2, 3, 4, 5]),
}

# Frames used to determine standing character scale. Later death frames are intentionally collapsed.
SCALE_REFERENCE = {
    "idle_core": [0, 1, 2, 3, 4, 5],
    "walk": [0, 1, 2, 3, 4, 5],
    "hit": [0, 1],
    "shoot": [0, 1, 2, 3],
    "vertical_attack": [0, 1, 2, 3],
    "phase_transition": [0, 1, 2, 3, 4],
    "death": [0, 1],
}


def gap_ranges(values: np.ndarray, max_occupancy: int = 1, min_len: int = 3) -> list[tuple[int, int]]:
    gaps: list[tuple[int, int]] = []
    start = None
    for index, value in enumerate(list(values) + [max_occupancy + 1]):
        if value <= max_occupancy and start is None:
            start = index
        elif value > max_occupancy and start is not None:
            if index - start >= min_len:
                gaps.append((start, index - 1))
            start = None
    return gaps


def split_boundaries(alpha: np.ndarray, count: int, axis: int) -> list[int]:
    if count == 1:
        return [0, alpha.shape[1 if axis == 0 else 0]]
    occupancy = (alpha > 12).sum(axis=axis)
    length = len(occupancy)
    gaps = gap_ranges(occupancy)
    internal = [(a, b) for a, b in gaps if a > 0 and b < length - 1]
    if len(internal) < count - 1:
        # Safe fallback for already grid-aligned sheets.
        return [round(i * length / count) for i in range(count + 1)]
    # Prefer gaps closest to ideal evenly spaced separators.
    selected: list[tuple[int, int]] = []
    for i in range(1, count):
        target = i * length / count
        candidates = [g for g in internal if g not in selected]
        chosen = min(candidates, key=lambda g: abs(((g[0] + g[1]) / 2.0) - target))
        selected.append(chosen)
    selected.sort()
    mids = [round((a + b) / 2.0) for a, b in selected]
    return [0, *mids, length]


def split_frames(image: Image.Image, cols: int, rows: int) -> list[Image.Image]:
    rgba = np.array(image.convert("RGBA"))
    alpha = rgba[:, :, 3]
    xb = split_boundaries(alpha, cols, axis=0)
    yb = split_boundaries(alpha, rows, axis=1)
    result: list[Image.Image] = []
    for row in range(rows):
        for col in range(cols):
            result.append(image.crop((xb[col], yb[row], xb[col + 1], yb[row + 1])).convert("RGBA"))
    return result


def largest_body_component(frame: Image.Image) -> tuple[int, int, int, int]:
    arr = np.array(frame.convert("RGBA"))
    rgb = arr[:, :, :3].astype(np.int16)
    alpha = arr[:, :, 3]
    channel_range = rgb.max(axis=2) - rgb.min(axis=2)
    brightness = rgb.mean(axis=2)
    # Metal/outline mask. Cyan VFX are intentionally excluded by channel spread.
    mask = (alpha > 24) & (channel_range < 90) & (brightness > 8) & (brightness < 245)
    labels, count = ndimage.label(mask)
    if count:
        sizes = ndimage.sum(mask, labels, range(1, count + 1))
        order = np.argsort(sizes)[::-1]
        # Merge the largest few components because black outlines can split armor plates.
        merged = np.zeros_like(mask)
        target_total = max(1.0, float(sizes[order[0]]) * 2.5)
        total = 0.0
        for idx in order[:12]:
            size = float(sizes[idx])
            if size < max(10.0, float(sizes[order[0]]) * 0.025):
                break
            merged |= labels == (int(idx) + 1)
            total += size
            if total >= target_total:
                break
        ys, xs = np.where(merged)
        if len(xs):
            return int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
    bbox = frame.getchannel("A").getbbox()
    if bbox is None:
        return 0, 0, frame.width, frame.height
    return bbox


def body_measurements(frames: Iterable[Image.Image]) -> list[tuple[tuple[int, int, int, int], int]]:
    result = []
    for frame in frames:
        bbox = largest_body_component(frame)
        result.append((bbox, bbox[3] - bbox[1]))
    return result


def normalize_animation(name: str, frames: list[Image.Image]) -> Image.Image:
    measurements = body_measurements(frames)
    ref_indices = SCALE_REFERENCE[name]
    reference_heights = [measurements[i][1] for i in ref_indices if measurements[i][1] > 0]
    scale = TARGET_BODY_HEIGHT / float(median(reference_heights))
    # Conservative cap prevents low-resolution idle art from becoming blurred by excessive upscaling.
    scale = min(scale, 1.20)

    normalized: list[Image.Image] = []
    for frame, (body_bbox, _) in zip(frames, measurements):
        new_size = (max(1, round(frame.width * scale)), max(1, round(frame.height * scale)))
        resized = frame.resize(new_size, Image.Resampling.NEAREST)
        bx0, by0, bx1, by1 = body_bbox
        anchor_x = ((bx0 + bx1) / 2.0) * scale
        ground_y = by1 * scale
        paste_x = round(ANCHOR_X - anchor_x)
        paste_y = round(GROUND_Y - ground_y)
        canvas = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
        canvas.alpha_composite(resized, (paste_x, paste_y))
        normalized.append(canvas)

    cols = SPECS[name][1]
    rows = SPECS[name][2]
    sheet = Image.new("RGBA", (CELL_W * cols, CELL_H * rows), (0, 0, 0, 0))
    for index, frame in enumerate(normalized):
        x = (index % cols) * CELL_W
        y = (index // cols) * CELL_H
        sheet.alpha_composite(frame, (x, y))
    out = OUTPUT / f"sentinel_{name}.png"
    sheet.save(out, optimize=True)
    print(f"{name}: {len(frames)} frames, scale={scale:.4f}, output={out.relative_to(ROOT)}")
    return sheet


def main() -> None:
    for name, (filename, cols, rows, _) in SPECS.items():
        image = Image.open(SOURCE / filename).convert("RGBA")
        frames = split_frames(image, cols, rows)
        normalize_animation(name, frames)


if __name__ == "__main__":
    main()
