#!/usr/bin/env python3
import json
import math
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Dict, List, Tuple

try:
    from PIL import Image
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

THEMES = {
    "gruvbox-dark": {
        "name": "Gruvbox Dark",
        "type": "dark",
        "bg": "#282828",
        "fg": "#ebdbb2",
        "border": "#fe8019",
        "accent": "#d79921",
        "palette": ["#282828", "#3c3836", "#cc241d", "#98971a", "#d79921", "#458588", "#b16286", "#689d6a", "#ebdbb2", "#928374", "#fb4934", "#b8bb26", "#fabd2f", "#83a598", "#d3869b", "#8ec07c"]
    },
    "gruvbox-light": {
        "name": "Gruvbox Light",
        "type": "light",
        "bg": "#fbf1c7",
        "fg": "#3c3836",
        "border": "#af3a03",
        "accent": "#b57614",
        "palette": ["#fbf1c7", "#ebdbb2", "#9d0006", "#79740e", "#b57614", "#076678", "#8f3f71", "#427b58", "#3c3836", "#928374", "#cc241d", "#98971a", "#d79921", "#458588", "#b16286", "#689d6a"]
    },
    "nord": {
        "name": "Nord",
        "type": "dark",
        "bg": "#2e3440",
        "fg": "#eceff4",
        "border": "#88c0d0",
        "accent": "#88c0d0",
        "palette": ["#2e3440", "#3b4252", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#8fbcbb", "#eceff4", "#4c566a", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#88c0d0"]
    },
    "everforest-dark": {
        "name": "Everforest Dark",
        "type": "dark",
        "bg": "#2d353b",
        "fg": "#d3c6aa",
        "border": "#a7c080",
        "accent": "#7fbbb3",
        "palette": ["#2d353b", "#343f44", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa", "#475258", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092"]
    },
    "everforest-light": {
        "name": "Everforest Light",
        "type": "light",
        "bg": "#fdfaf3",
        "fg": "#5c6a72",
        "border": "#8da101",
        "accent": "#3a94c5",
        "palette": [
            "#fdfaf3", "#f4f0d9",
            "#f85552", "#8da101",
            "#dfa000", "#3a94c5",
            "#df69ba", "#35a77c",
            "#5c6a72", "#939f91",
            "#f85552", "#8da101",
            "#dfa000", "#3a94c5",
            "#df69ba", "#35a77c"
        ]
    },
    "catppuccin-mocha": {
        "name": "Catppuccin Mocha",
        "type": "dark",
        "bg": "#1e1e2e",
        "fg": "#cdd6f4",
        "border": "#cba6f7",
        "accent": "#89b4fa",
        "palette": ["#1e1e2e", "#181825", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#cdd6f4", "#585b70", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5"]
    },
    "catppuccin-latte": {
        "name": "Catppuccin Latte",
        "type": "light",
        "bg": "#eff1f5",
        "fg": "#4c4f69",
        "border": "#8839ef",
        "accent": "#1e66f5",
        "palette": ["#eff1f5", "#e6e9ef", "#d20f39", "#40a02b", "#df8e1d", "#1e66f5", "#ea76cb", "#179299", "#4c4f69", "#9ca0b0", "#d20f39", "#40a02b", "#df8e1d", "#1e66f5", "#ea76cb", "#179299"]
    },
    "tokyo-night": {
        "name": "Tokyo Night",
        "type": "dark",
        "bg": "#1a1b26",
        "fg": "#c0caf5",
        "border": "#7aa2f7",
        "accent": "#7dcfff",
        "palette": ["#1a1b26", "#16161e", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#c0caf5", "#414868", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff"]
    },
    "rose-pine": {
        "name": "Rosé Pine",
        "type": "dark",
        "bg": "#191724",
        "fg": "#e0def4",
        "border": "#9ccfd8",
        "accent": "#c4a7e7",
        "palette": ["#191724", "#1f1d2e", "#eb6f92", "#9ccfd8", "#f6c177", "#31748f", "#c4a7e7", "#ebbcba", "#e0def4", "#6e6a86", "#eb6f92", "#9ccfd8", "#f6c177", "#31748f", "#c4a7e7", "#ebbcba"]
    },
    "dracula": {
        "name": "Dracula",
        "type": "dark",
        "bg": "#282a36",
        "fg": "#f8f8f2",
        "border": "#bd93f9",
        "accent": "#ff79c6",
        "palette": ["#282a36", "#44475a", "#ff5555", "#50fa7b", "#f1fa8c", "#bd93f9", "#ff79c6", "#8be9fd", "#f8f8f2", "#6272a4", "#ff5555", "#50fa7b", "#f1fa8c", "#bd93f9", "#ff79c6", "#8be9fd"]
    },
    "solarized-dark": {
        "name": "Solarized Dark",
        "type": "dark",
        "bg": "#002b36",
        "fg": "#839496",
        "border": "#268bd2",
        "accent": "#2aa198",
        "palette": ["#002b36", "#073642", "#dc322f", "#859900", "#b58900", "#268bd2", "#d33682", "#2aa198", "#839496", "#586e75", "#cb4b16", "#586e75", "#657b83", "#839496", "#6c71c4", "#93a1a1"]
    },
    "solarized-light": {
        "name": "Solarized Light",
        "type": "light",
        "bg": "#fdf6e3",
        "fg": "#657b83",
        "border": "#268bd2",
        "accent": "#2aa198",
        "palette": ["#fdf6e3", "#eee8d5", "#dc322f", "#859900", "#b58900", "#268bd2", "#d33682", "#2aa198", "#657b83", "#93a1a1", "#cb4b16", "#839496", "#657b83", "#586e75", "#6c71c4", "#073642"]
    },
    "one-dark": {
        "name": "One Dark",
        "type": "dark",
        "bg": "#282c34",
        "fg": "#abb2bf",
        "border": "#56b6c2",
        "accent": "#61afef",
        "palette": ["#282c34", "#3e4451", "#e06c75", "#98c379", "#e5c07b", "#61afef", "#c678dd", "#56b6c2", "#abb2bf", "#5c6370", "#e06c75", "#98c379", "#e5c07b", "#61afef", "#c678dd", "#56b6c2"]
    },
    "kanagawa": {
        "name": "Kanagawa",
        "type": "dark",
        "bg": "#1f1f28",
        "fg": "#dcd7ba",
        "border": "#7e9cd8",
        "accent": "#957fb8",
        "palette": [
            "#1f1f28", "#2a2a37",
            "#c34043", "#76946a",
            "#c0a36e", "#7e9cd8",
            "#957fb8", "#6a9589",
            "#dcd7ba", "#727169",
            "#e82424", "#98bb6c",
            "#e6c384", "#7fb4ca",
            "#938aa9", "#7aa89f"
        ]
    },
    "github-dark": {
        "name": "GitHub Dark",
        "type": "dark",
        "bg": "#0d1117",
        "fg": "#c9d1d9",
        "border": "#58a6ff",
        "accent": "#79c0ff",
        "palette": [
            "#0d1117", "#161b22",
            "#ff7b72", "#3fb950",
            "#d29922", "#58a6ff",
            "#bc8cff", "#39c5cf",
            "#c9d1d9", "#8b949e",
            "#ff7b72", "#56d364",
            "#e3b341", "#79c0ff",
            "#d2a8ff", "#56d4dd"
        ]
    },
    "material-ocean": {
        "name": "Material Ocean",
        "type": "dark",
        "bg": "#0f111a",
        "fg": "#a6accd",
        "border": "#82aaff",
        "accent": "#c792ea",
        "palette": [
            "#0f111a", "#1a1c25",
            "#f07178", "#c3e88d",
            "#ffcb6b", "#82aaff",
            "#c792ea", "#89ddff",
            "#a6accd", "#676e95",
            "#f07178", "#c3e88d",
            "#ffcb6b", "#82aaff",
            "#c792ea", "#89ddff"
        ]
    },
    "ayu-dark": {
        "name": "Ayu Dark",
        "type": "dark",
        "bg": "#0b0e14",
        "fg": "#bfbdb6",
        "border": "#39bae6",
        "accent": "#59c2ff",
        "palette": [
            "#0b0e14", "#131721",
            "#f07178", "#aad94c",
            "#ffb454", "#39bae6",
            "#d2a6ff", "#95e6cb",
            "#bfbdb6", "#626a73",
            "#f28779", "#bae67e",
            "#ffd580", "#59c2ff",
            "#d4bfff", "#c7ffea"
        ]
    },
    "oxocarbon": {
        "name": "Oxocarbon",
        "type": "dark",
        "bg": "#161616",
        "fg": "#dde1e6",
        "border": "#78a9ff",
        "accent": "#be95ff",
        "palette": [
            "#161616", "#262626",
            "#ee5396", "#42be65",
            "#ffe97b", "#78a9ff",
            "#be95ff", "#33b1ff",
            "#dde1e6", "#525252",
            "#ff7eb6", "#08bdba",
            "#ff7eb6", "#78a9ff",
            "#be95ff", "#82cfff"
        ]
    },
    "monokai-pro": {
        "name": "Monokai Pro",
        "type": "dark",
        "bg": "#2d2a2e",
        "fg": "#fcfcfa",
        "border": "#78dce8",
        "accent": "#ab9df2",
        "palette": [
            "#2d2a2e", "#403e41",
            "#ff6188", "#a9dc76",
            "#ffd866", "#78dce8",
            "#ab9df2", "#fc9867",
            "#fcfcfa", "#727072",
            "#ff6188", "#a9dc76",
            "#ffd866", "#78dce8",
            "#ab9df2", "#fc9867"
        ]
    },
    "nightfox": {
        "name": "Nightfox",
        "type": "dark",
        "bg": "#192330",
        "fg": "#cdcecf",
        "border": "#719cd6",
        "accent": "#bb9af7",
        "palette": [
            "#192330", "#212e3f",
            "#c94f6d", "#81b29a",
            "#dbc074", "#719cd6",
            "#9d79d6", "#63cdcf",
            "#cdcecf", "#738091",
            "#d16983", "#8ebaa4",
            "#e0c989", "#86abdc",
            "#baa1e2", "#7ad5d6"
        ]
    },
    "carbonfox": {
        "name": "Carbonfox",
        "type": "dark",
        "bg": "#161616",
        "fg": "#f2f4f8",
        "border": "#78a9ff",
        "accent": "#be95ff",
        "palette": [
            "#161616", "#262626",
            "#ee5396", "#25be6a",
            "#08bdba", "#78a9ff",
            "#be95ff", "#33b1ff",
            "#f2f4f8", "#525252",
            "#ff7eb6", "#42be65",
            "#3ddbd9", "#78a9ff",
            "#be95ff", "#82cfff"
        ]
    }
}

def hex_to_rgb(hex_str: str) -> Tuple[int, int, int]:
    hex_str = hex_str.lstrip("#")
    if len(hex_str) == 3:
        hex_str = "".join([c*2 for c in hex_str])
    return int(hex_str[0:2], 16), int(hex_str[2:4], 16), int(hex_str[4:6], 16)

def rgb_to_hex(r: int, g: int, b: int) -> str:
    return f"#{r:02x}{g:02x}{b:02x}"

def rgb_to_lab(r: int, g: int, b: int) -> Tuple[float, float, float]:
    def pivot_rgb(c: float) -> float:
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else math.pow((c + 0.055) / 1.055, 2.4)

    rl, gl, bl = pivot_rgb(r), pivot_rgb(g), pivot_rgb(b)

    X = (rl * 0.4124 + gl * 0.3576 + bl * 0.1805) / 0.95047
    Y = (rl * 0.2126 + gl * 0.7152 + bl * 0.0722) / 1.00000
    Z = (rl * 0.0193 + gl * 0.1192 + bl * 0.9505) / 1.08883

    def pivot_xyz(n: float) -> float:
        return math.pow(n, 1.0/3.0) if n > 0.008856 else (7.787 * n) + (16.0 / 116.0)

    fx, fy, fz = pivot_xyz(X), pivot_xyz(Y), pivot_xyz(Z)

    L = (116.0 * fy) - 16.0
    a = 500.0 * (fx - fy)
    b_val = 200.0 * (fy - fz)
    return L, a, b_val

def ciede2000(lab1: Tuple[float, float, float], lab2: Tuple[float, float, float]) -> float:
    L1, a1, b1 = lab1
    L2, a2, b2 = lab2

    C1 = math.sqrt(a1 * a1 + b1 * b1)
    C2 = math.sqrt(a2 * a2 + b2 * b2)
    C_bar = (C1 + C2) / 2.0

    G = 0.5 * (1.0 - math.sqrt(C_bar**7 / (C_bar**7 + 25.0**7)))

    a1_prime = (1.0 + G) * a1
    a2_prime = (1.0 + G) * a2

    C1_prime = math.sqrt(a1_prime**2 + b1**2)
    C2_prime = math.sqrt(a2_prime**2 + b2**2)

    h1_prime = math.degrees(math.atan2(b1, a1_prime)) % 360.0
    h2_prime = math.degrees(math.atan2(b2, a2_prime)) % 360.0

    dL_prime = L2 - L1
    dC_prime = C2_prime - C1_prime

    if C1_prime * C2_prime == 0:
        dh_prime = 0.0
    elif abs(h1_prime - h2_prime) <= 180.0:
        dh_prime = h2_prime - h1_prime
    elif h2_prime <= h1_prime:
        dh_prime = h2_prime - h1_prime + 360.0
    else:
        dh_prime = h2_prime - h1_prime - 360.0

    dH_prime = 2.0 * math.sqrt(C1_prime * C2_prime) * math.sin(math.radians(dh_prime / 2.0))

    L_bar_prime = (L1 + L2) / 2.0
    C_bar_prime = (C1_prime + C2_prime) / 2.0

    if C1_prime * C2_prime == 0:
        h_bar_prime = h1_prime + h2_prime
    elif abs(h1_prime - h2_prime) <= 180.0:
        h_bar_prime = (h1_prime + h2_prime) / 2.0
    elif (h1_prime + h2_prime) < 360.0:
        h_bar_prime = (h1_prime + h2_prime + 360.0) / 2.0
    else:
        h_bar_prime = (h1_prime + h2_prime - 360.0) / 2.0

    T = (1.0 - 0.17 * math.cos(math.radians(h_bar_prime - 30.0))
             + 0.24 * math.cos(math.radians(2.0 * h_bar_prime))
             + 0.32 * math.cos(math.radians(3.0 * h_bar_prime + 6.0))
             - 0.20 * math.cos(math.radians(4.0 * h_bar_prime - 63.0)))

    deg_diff = (h_bar_prime - 275.0) / 25.0
    del_theta = 30.0 * math.exp(-(deg_diff ** 2))
    R_C = 2.0 * math.sqrt(C_bar_prime**7 / (C_bar_prime**7 + 25.0**7))
    S_L = 1.0 + (0.015 * ((L_bar_prime - 50.0)**2)) / math.sqrt(20.0 + (L_bar_prime - 50.0)**2)
    S_C = 1.0 + 0.045 * C_bar_prime
    S_H = 1.0 + 0.015 * C_bar_prime * T
    R_T = -math.sin(math.radians(2.0 * del_theta)) * R_C

    dL_scaled = dL_prime / S_L
    dC_scaled = dC_prime / S_C
    dH_scaled = dH_prime / S_H

    return math.sqrt(dL_scaled**2 + dC_scaled**2 + dH_scaled**2 + R_T * dC_scaled * dH_scaled)

def lab_chroma(lab: Tuple[float, float, float]) -> float:
    return math.sqrt(lab[1] ** 2 + lab[2] ** 2)

def relative_luminance(r: int, g: int, b: int) -> float:
    def channel_lum(c: float) -> float:
        c /= 255.0
        return c / 12.92 if c <= 0.04045 else math.pow((c + 0.055) / 1.055, 2.4)
    return 0.2126 * channel_lum(r) + 0.7152 * channel_lum(g) + 0.0722 * channel_lum(b)

def contrast_ratio(rgb1: Tuple[int, int, int], rgb2: Tuple[int, int, int]) -> float:
    l1 = relative_luminance(*rgb1)
    l2 = relative_luminance(*rgb2)
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

def ensure_contrast(fg_hex: str, bg_hex: str, min_ratio: float = 4.5) -> str:
    fg_rgb = hex_to_rgb(fg_hex)
    bg_rgb = hex_to_rgb(bg_hex)

    if contrast_ratio(fg_rgb, bg_rgb) >= min_ratio:
        return fg_hex

    bg_lum = relative_luminance(*bg_rgb)
    is_bg_dark = bg_lum < 0.5

    r, g, b = fg_rgb
    step = 5 if is_bg_dark else -5

    for _ in range(50):
        r = max(0, min(255, r + step))
        g = max(0, min(255, g + step))
        b = max(0, min(255, b + step))

        if contrast_ratio((r, g, b), bg_rgb) >= min_ratio:
            return rgb_to_hex(r, g, b)

    return rgb_to_hex(r, g, b)

VIDEO_EXTENSIONS = {
    ".mp4", ".mkv", ".webm", ".avi", ".mov", ".flv", ".m4v", ".wmv", ".gif"
}

def is_video_file(path: str) -> bool:
    _, ext = os.path.splitext(path)
    return ext.lower() in VIDEO_EXTENSIONS

def extract_video_frame(video_path: str) -> str:
    """Extracts a representative frame from a video file and saves it in ~/.cache/theme_matcher/current_frame.png."""
    if not os.path.isfile(video_path):
        raise FileNotFoundError(f"Wallpaper video file not found: {video_path}")

    cache_dir = os.path.expanduser("~/.cache/theme_matcher")
    os.makedirs(cache_dir, exist_ok=True)
    frame_path = os.path.join(cache_dir, "current_frame.png")

    ffmpeg_bin = shutil.which("ffmpeg")
    if ffmpeg_bin:
        # Try seeking 1 second in for a representative frame
        cmd = [
            ffmpeg_bin, "-ss", "00:00:01", "-i", video_path,
            "-vframes", "1", "-y", frame_path
        ]
        try:
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5)
            if res.returncode == 0 and os.path.exists(frame_path) and os.path.getsize(frame_path) > 0:
                return frame_path
        except Exception:
            pass

        # Fallback to frame 0 if seeking 1s failed
        cmd_fallback = [
            ffmpeg_bin, "-i", video_path,
            "-vframes", "1", "-y", frame_path
        ]
        try:
            res = subprocess.run(cmd_fallback, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5)
            if res.returncode == 0 and os.path.exists(frame_path) and os.path.getsize(frame_path) > 0:
                return frame_path
        except Exception:
            pass

    # ImageMagick fallback
    cmd_binary = "magick" if shutil.which("magick") else ("convert" if shutil.which("convert") else None)
    if cmd_binary:
        cmd = [cmd_binary, f"{video_path}[0]", frame_path]
        try:
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=5)
            if res.returncode == 0 and os.path.exists(frame_path) and os.path.getsize(frame_path) > 0:
                return frame_path
        except Exception:
            pass

    raise RuntimeError(f"Could not extract frame from video wallpaper '{video_path}'. Ensure ffmpeg or ImageMagick is installed.")

def extract_image_palette(image_path: str, max_colors: int = 32) -> Tuple[List[Tuple[Tuple[int, int, int], float]], float]:
    if not os.path.isfile(image_path):
        raise FileNotFoundError(f"Wallpaper file not found: {image_path}")

    cmd_binary = "magick" if shutil.which("magick") else ("convert" if shutil.which("convert") else None)

    if cmd_binary:
        cmd = [
            cmd_binary, image_path,
            "-resize", "256x256!",
            "-depth", "8",
            "-colors", str(max_colors),
            "-unique-colors",
            "txt:-"
        ]
        try:
            res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, check=True, timeout=5)
            colors = []
            total_pixels = 0
            total_luminance = 0.0

            for line in res.stdout.splitlines():
                if "#" not in line and "(" not in line:
                    continue

                r, g, b = None, None, None
                match_rgb = re.search(r"\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)", line)
                if match_rgb:
                    r, g, b = int(match_rgb.group(1)), int(match_rgb.group(2)), int(match_rgb.group(3))
                else:
                    match_hex = re.search(r"#([0-9a-fA-F]{6})", line)
                    if match_hex:
                        r, g, b = hex_to_rgb(match_hex.group(1))

                if r is not None:
                    cnt_match = re.match(r"^\s*(\d+):", line)
                    count = int(cnt_match.group(1)) if cnt_match else 1

                    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                    total_luminance += lum * count
                    total_pixels += count
                    colors.append(((r, g, b), float(count)))

            if colors and total_pixels > 0:
                normalized_colors = [(rgb, weight / total_pixels) for rgb, weight in colors]
                mean_luminance = total_luminance / total_pixels
                return normalized_colors, mean_luminance
        except Exception as e:
            print(f"ImageMagick extraction notice: {e}", file=sys.stderr)

    if HAS_PIL:
        try:
            img = Image.open(image_path).convert("RGB").resize((256, 256))
            quantized = img.quantize(colors=max_colors)
            palette = quantized.getpalette()[:max_colors * 3]
            colors = []
            total_pixels = 0
            total_lum = 0.0

            raw_colors = quantized.getcolors()
            if raw_colors:
                for count, idx in raw_colors:
                    r, g, b = palette[idx * 3], palette[idx * 3 + 1], palette[idx * 3 + 2]
                    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
                    total_lum += lum * count
                    total_pixels += count
                    colors.append(((r, g, b), float(count)))

            if colors and total_pixels > 0:
                normalized_colors = [(rgb, weight / total_pixels) for rgb, weight in colors]
                mean_lum = total_lum / total_pixels
                return normalized_colors, mean_lum
        except Exception as e:
            print(f"PIL extraction notice: {e}", file=sys.stderr)

    return [((40, 40, 40), 1.0)], 40.0

def extract_wallpaper_accents(image_colors: List[Tuple[Tuple[int, int, int], float]], fallback_accent: str, fallback_border: str) -> List[str]:
    candidates = []
    for rgb, weight in image_colors:
        lab = rgb_to_lab(*rgb)
        chroma = lab_chroma(lab)
        if chroma > 15.0:
            candidates.append((rgb, lab, chroma, weight))

    candidates.sort(key=lambda x: x[2], reverse=True)

    selected_rgbs: List[Tuple[int, int, int]] = []
    selected_labs: List[Tuple[float, float, float]] = []

    for rgb, lab, chroma, weight in candidates:
        if not selected_labs:
            selected_rgbs.append(rgb)
            selected_labs.append(lab)
        else:
            min_dist = min(ciede2000(lab, prev_lab) for prev_lab in selected_labs)
            if min_dist > 12.0:
                selected_rgbs.append(rgb)
                selected_labs.append(lab)

        if len(selected_rgbs) >= 3:
            break

    accents_hex = [rgb_to_hex(*c) for c in selected_rgbs]

    if not accents_hex:
        accents_hex = [fallback_accent, fallback_border]
    elif len(accents_hex) == 1:
        c1 = hex_to_rgb(accents_hex[0])
        c2 = (min(255, int(c1[0] * 1.3)), min(255, int(c1[1] * 1.3)), min(255, int(c1[2] * 1.3)))
        accents_hex.append(rgb_to_hex(*c2))

    return accents_hex

def match_theme(image_colors: List[Tuple[Tuple[int, int, int], float]], mean_lum: float) -> str:
    image_labs_weighted = [(rgb_to_lab(*rgb), weight) for rgb, weight in image_colors]

    sorted_by_weight = sorted(image_labs_weighted, key=lambda x: x[1], reverse=True)
    dominant_lab = sorted_by_weight[0][0] if sorted_by_weight else rgb_to_lab(40, 40, 40)

    vibrant_labs = [item[0] for item in sorted(image_labs_weighted, key=lambda x: lab_chroma(x[0]), reverse=True)[:3]]
    is_image_dark = mean_lum < 128.0 or dominant_lab[0] < 50.0

    best_score = float("inf")
    best_theme_key = "gruvbox-dark"

    for theme_key, theme_data in THEMES.items():
        theme_bg_lab = rgb_to_lab(*hex_to_rgb(theme_data["bg"]))
        theme_accent_lab = rgb_to_lab(*hex_to_rgb(theme_data["accent"]))
        theme_border_lab = rgb_to_lab(*hex_to_rgb(theme_data["border"]))
        theme_palette_labs = [rgb_to_lab(*hex_to_rgb(hex_c)) for hex_c in theme_data["palette"]]
        theme_is_dark = theme_data["type"] == "dark"

        fwd_score = 0.0
        for lab_img, weight in image_labs_weighted:
            min_d = min(ciede2000(lab_img, lab_t) for lab_t in theme_palette_labs)
            fwd_score += min_d * weight

        bg_distance = ciede2000(dominant_lab, theme_bg_lab)

        if vibrant_labs:
            accent_distance = min(
                min(ciede2000(v_lab, theme_accent_lab), ciede2000(v_lab, theme_border_lab))
                for v_lab in vibrant_labs
            )
        else:
            accent_distance = ciede2000(dominant_lab, theme_accent_lab)

        total_score = (fwd_score * 0.40) + (bg_distance * 0.30) + (accent_distance * 0.30)

        if is_image_dark != theme_is_dark:
            total_score += 50.0

        if total_score < best_score:
            best_score = total_score
            best_theme_key = theme_key

    return best_theme_key

def apply_hyprland_theme(theme: dict, dynamic_accents: List[str]):
    if not shutil.which("hyprctl"):
        return

    border_colors = [c.lstrip("#") for c in dynamic_accents]
    if len(border_colors) == 1:
        border_colors.append(theme["border"].lstrip("#"))

    formatted_colors = [f'"rgba({c}ff)"' for c in border_colors]
    colors_str = ", ".join(formatted_colors)
    bg_hex = theme["bg"].lstrip("#")

    hypr_dir = os.path.expanduser("~/.config/hypr")
    os.makedirs(hypr_dir, exist_ok=True)
    theme_lua_path = os.path.join(hypr_dir, "theme.lua")
    
    lua_content = (
        f"-- Auto-generated Hyprland theme: {theme['name']}\n"
        f"hl.config({{\n"
        f"    general = {{\n"
        f"        col = {{\n"
        f"            active_border   = {{ colors = {{{colors_str}}}, angle = 45 }},\n"
        f"            inactive_border = \x22rgba({bg_hex}aa)\x22,\n"
        f"        }},\n"
        f"    }},\n"
        f"}})\n"
    )
    with open(theme_lua_path, "w", encoding="utf-8") as f:
        f.write(lua_content)

    lua_code = (
        f"hl.config({{ general = {{ col = {{ "
        f"active_border = {{ colors = {{{colors_str}}}, angle = 45 }}, "
        f"inactive_border = 'rgba({bg_hex}aa)' "
        f"}} }} }})"
    )
    try:
        subprocess.run(["hyprctl", "repl", lua_code], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
        subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
    except Exception:
        pass

def apply_terminal_themes(theme: dict, dynamic_accents: List[str]):
    kitty_dir = os.path.expanduser("~/.config/kitty")
    os.makedirs(kitty_dir, exist_ok=True)
    conf_path = os.path.join(kitty_dir, "theme.conf")

    bg = theme["bg"]
    fg = ensure_contrast(theme["fg"], bg, min_ratio=4.5)
    accent = dynamic_accents[0] if dynamic_accents else theme["accent"]
    border = dynamic_accents[1] if len(dynamic_accents) > 1 else theme["border"]

    lines = [
        f"# Auto-generated theme: {theme['name']} (Dynamic Accents)",
        f"background {bg}",
        f"foreground {fg}",
        f"selection_background {accent}",
        f"selection_foreground {bg}",
        f"cursor {fg}",
        f"active_border_color {accent}",
        f"inactive_border_color {bg}",
    ]
    for idx, c in enumerate(theme["palette"]):
        lines.append(f"color{idx} {c}")

    with open(conf_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    main_kitty_conf = os.path.join(kitty_dir, "kitty.conf")
    if not os.path.exists(main_kitty_conf):
        with open(main_kitty_conf, "w", encoding="utf-8") as f:
            f.write("include theme.conf\n")

    if shutil.which("pkill"):
        try:
            subprocess.run(["pkill", "-USR1", "kitty"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
        except Exception:
            pass

def apply_shell_themes(theme: dict, dynamic_accents: List[str]):
    config_dir = os.path.expanduser("~/.config/theme_matcher")
    os.makedirs(config_dir, exist_ok=True)

    bg, fg = theme["bg"], theme["fg"]
    fg = ensure_contrast(fg, bg, min_ratio=4.5)
    accent = dynamic_accents[0] if dynamic_accents else theme["accent"]
    border = dynamic_accents[1] if len(dynamic_accents) > 1 else theme["border"]
    p = theme["palette"]

    sh_content = [
        f"# Theme: {theme['name']}",
        f"export THEME_NAME='{theme['name']}'",
        f"export COLOR_BG='{bg}'",
        f"export COLOR_FG='{fg}'",
        f"export COLOR_ACCENT='{accent}'",
        f"export COLOR_BORDER='{border}'",
        f"export FZF_DEFAULT_OPTS='--color=bg+:{p[1]},bg:{bg},spinner:{accent},hl:{border},fg:{fg},header:{border},info:{p[5]},pointer:{accent},marker:{accent},prompt:{border},hl+:{border}'",
    ]
    with open(os.path.join(config_dir, "theme.sh"), "w", encoding="utf-8") as f:
        f.write("\n".join(sh_content) + "\n")

    fish_content = [
        f"# Fish Theme: {theme['name']}",
        f"set -U fish_color_normal {fg.lstrip('#')}",
        f"set -U fish_color_command {accent.lstrip('#')}",
        f"set -U fish_color_keyword {border.lstrip('#')}",
        f"set -U fish_color_quote {p[3].lstrip('#')}",
        f"set -U fish_color_redirection {p[5].lstrip('#')}",
        f"set -U fish_color_end {p[6].lstrip('#')}",
        f"set -U fish_color_error {p[2].lstrip('#')}",
        f"set -U fish_color_param {fg.lstrip('#')}",
        f"set -U fish_color_comment {p[9].lstrip('#')}",
        f"set -U fish_color_selection --background={p[1].lstrip('#')}",
        f"set -U fish_color_search_match --background={p[1].lstrip('#')}",
        f"set -U fish_color_operator {p[7].lstrip('#')}",
        f"set -U fish_color_escape {p[7].lstrip('#')}",
        f"set -U fish_color_autosuggestion {p[9].lstrip('#')}",
    ]
    fish_file = os.path.join(config_dir, "theme.fish")
    with open(fish_file, "w", encoding="utf-8") as f:
        f.write("\n".join(fish_content) + "\n")

    if shutil.which("fish"):
        try:
            subprocess.run(["fish", fish_file], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
        except Exception:
            pass

def get_hyprland_monitors() -> list[str]:
    try:
        res = subprocess.run(["hyprctl", "monitors", "-j"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=2)
        if res.returncode == 0 and res.stdout:
            data = json.loads(res.stdout)
            names = [m["name"] for m in data if "name" in m]
            if names:
                return names
    except Exception:
        pass
    return ["eDP-1"]

def apply_wallpaper_if_needed(wallpaper_path: str, fallback_frame_path: str = ""):
    if not os.path.isfile(wallpaper_path):
        return

    monitors = get_hyprland_monitors()

    if is_video_file(wallpaper_path):
        if shutil.which("killall"):
            subprocess.run(["killall", "-9", "hyprpaper", "mpvpaper"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(0.2)

        if shutil.which("mpvpaper"):
            try:
                env = os.environ.copy()
                mon_arg = "*" if not monitors else monitors[0]
                subprocess.Popen(["mpvpaper", "-l", "background", "-o", "no-audio loop --panscan=1.0", mon_arg, wallpaper_path], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
                return
            except Exception as e:
                print(f"Notice starting mpvpaper: {e}", file=sys.stderr)

        # Fallback to static frame with hyprpaper if mpvpaper is missing/failed
        if fallback_frame_path and os.path.isfile(fallback_frame_path):
            wallpaper_path = fallback_frame_path
        else:
            return
    else:
        # Kill mpvpaper if running so static wallpaper is visible
        if shutil.which("killall"):
            subprocess.run(["killall", "-9", "mpvpaper"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    hypr_dir = os.path.expanduser("~/.config/hypr")
    os.makedirs(hypr_dir, exist_ok=True)
    conf_path = os.path.join(hypr_dir, "hyprpaper.conf")
    
    conf_lines = [
        "ipc = on",
        "splash = false",
        f"preload = {wallpaper_path}"
    ]
    if monitors:
        for mon in monitors:
            conf_lines.append(f"wallpaper {{\n    monitor = {mon}\n    path = {wallpaper_path}\n}}")
    else:
        conf_lines.append(f"wallpaper {{\n    monitor = \n    path = {wallpaper_path}\n}}")

    try:
        with open(conf_path, "w", encoding="utf-8") as f:
            f.write("\n".join(conf_lines) + "\n")
    except Exception:
        pass

    if shutil.which("hyprpaper"):
        try:
            subprocess.run(["killall", "-9", "hyprpaper"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(0.2)
            env = os.environ.copy()
            subprocess.Popen(["hyprpaper", "-c", conf_path], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        except Exception:
            pass
    elif shutil.which("swww"):
        try:
            subprocess.run(["swww", "img", wallpaper_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
        except Exception:
            pass
    elif shutil.which("awww"):
        try:
            subprocess.run(["awww", "img", wallpaper_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
        except Exception:
            pass

def apply_pywal_cache(theme: dict, wallpaper_path: str, dynamic_accents: List[str]):
    wal_dir = os.path.expanduser("~/.cache/wal")
    os.makedirs(wal_dir, exist_ok=True)

    accent = dynamic_accents[0] if dynamic_accents else theme["accent"]
    border = dynamic_accents[1] if len(dynamic_accents) > 1 else theme["border"]

    colors_data = {
        "wallpaper": wallpaper_path,
        "alpha": "100",
        "special": {
            "background": theme["bg"],
            "foreground": theme["fg"],
            "cursor": theme["fg"]
        },
        "colors": {f"color{i}": c for i, c in enumerate(theme["palette"])}
    }

    with open(os.path.join(wal_dir, "colors.json"), "w", encoding="utf-8") as f:
        json.dump(colors_data, f, indent=4)

    with open(os.path.join(wal_dir, "colors-hyprland.conf"), "w", encoding="utf-8") as f:
        f.write(f"$background = rgb({theme['bg'].lstrip('#')})\n")
        f.write(f"$foreground = rgb({theme['fg'].lstrip('#')})\n")
        f.write(f"$active_border = rgb({border.lstrip('#')})\n")
        f.write(f"$accent = rgb({accent.lstrip('#')})\n")

def notify_user(theme: dict, dynamic_accents: List[str]):
    if shutil.which("notify-send"):
        try:
            accents_str = ", ".join(dynamic_accents)
            subprocess.run([
                "notify-send",
                "-i", "preferences-desktop-theme",
                "Theme & Accents Matched",
                f"Base Theme: {theme['name']} ({theme['type']})\nDynamic Accents: {accents_str}"
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=2)
        except Exception:
            pass

def apply_vencord_theme(theme: dict, dynamic_accents: List[str], wallpaper_path: str = ""):
    bg = theme["bg"]
    fg = ensure_contrast(theme["fg"], bg, min_ratio=4.5)
    accent = dynamic_accents[0] if dynamic_accents else theme["accent"]
    accent_secondary = dynamic_accents[1] if len(dynamic_accents) > 1 else theme["border"]
    p = theme["palette"]

    r, g, b = hex_to_rgb(bg)
    is_dark = theme["type"] == "dark"
    factor_sec = 0.85 if is_dark else 1.05
    factor_ter = 0.70 if is_dark else 1.10

    bg_sec_rgb = (max(0, min(255, int(r * factor_sec))), max(0, min(255, int(g * factor_sec))), max(0, min(255, int(b * factor_sec))))
    bg_ter_rgb = (max(0, min(255, int(r * factor_ter))), max(0, min(255, int(g * factor_ter))), max(0, min(255, int(b * factor_ter))))

    bg_sec = rgb_to_hex(*bg_sec_rgb)
    bg_ter = rgb_to_hex(*bg_ter_rgb)

    theme_meta = (
        "/**\n"
        " * @name DynamicTheme\n"
        " * @author theme_matcher\n"
        " * @description Auto-generated dynamic color theme for Vencord/Vesktop\n"
        " * @version 1.0.0\n"
        " */\n\n"
    )

    css_body = (
        f":root, .theme-dark, .theme-light {{\n"
        f"    --background-primary: {bg} !important;\n"
        f"    --background-secondary: {bg_sec} !important;\n"
        f"    --background-secondary-alt: {bg_ter} !important;\n"
        f"    --background-tertiary: {bg_ter} !important;\n"
        f"    --background-accent: {accent} !important;\n"
        f"    --background-floating: {bg} !important;\n"
        f"    --background-nested-floating: {bg_sec} !important;\n"
        f"    --background-mobile-primary: {bg} !important;\n"
        f"    --background-mobile-secondary: {bg_sec} !important;\n"
        f"    --text-normal: {fg} !important;\n"
        f"    --text-muted: {p[9] if len(p) > 9 else fg} !important;\n"
        f"    --text-link: {accent_secondary} !important;\n"
        f"    --header-primary: {fg} !important;\n"
        f"    --header-secondary: {p[8] if len(p) > 8 else fg} !important;\n"
        f"    --interactive-normal: {fg} !important;\n"
        f"    --interactive-hover: #ffffff !important;\n"
        f"    --interactive-active: #ffffff !important;\n"
        f"    --interactive-muted: {p[9] if len(p) > 9 else fg} !important;\n"
        f"    --brand-experiment: {accent} !important;\n"
        f"    --brand-experiment-hover: {accent_secondary} !important;\n"
        f"    --brand-experiment-500: {accent} !important;\n"
        f"    --brand-experiment-560: {accent_secondary} !important;\n"
        f"    --button-positive-background: {p[3] if len(p) > 3 else accent} !important;\n"
        f"    --button-danger-background: {p[2] if len(p) > 2 else accent} !important;\n"
        f"}}\n"
    )

    theme_filename = "dynamic.theme.css"
    theme_file_paths = [
        os.path.expanduser(f"~/.config/vesktop/themes/{theme_filename}"),
        os.path.expanduser(f"~/.config/Vencord/themes/{theme_filename}"),
        os.path.expanduser(f"~/.config/discord/Vencord/themes/{theme_filename}")
    ]

    for t_path in theme_file_paths:
        parent_dir = os.path.dirname(t_path)
        os.makedirs(parent_dir, exist_ok=True)
        try:
            with open(t_path, "w", encoding="utf-8") as f:
                f.write(theme_meta + css_body)
        except Exception as e:
            print(f"Notice writing theme to {t_path}: {e}", file=sys.stderr)

    quick_css_paths = [
        os.path.expanduser("~/.config/vesktop/settings/quickCss.css"),
        os.path.expanduser("~/.config/Vencord/settings/quickCss.css"),
        os.path.expanduser("~/.config/discord/Vencord/settings/quickCss.css")
    ]
    for css_path in quick_css_paths:
        parent_dir = os.path.dirname(css_path)
        if os.path.isdir(parent_dir):
            try:
                with open(css_path, "w", encoding="utf-8") as f:
                    f.write(theme_meta + css_body)
            except Exception as e:
                pass

    settings_paths = [
        os.path.expanduser("~/.config/vesktop/settings/settings.json"),
        os.path.expanduser("~/.config/vesktop/settings.json"),
        os.path.expanduser("~/.config/Vencord/settings/settings.json")
    ]
    for s_path in settings_paths:
        if os.path.isfile(s_path):
            try:
                with open(s_path, "r", encoding="utf-8") as f:
                    data = json.load(f)
                enabled = data.get("enabledThemes", [])
                updated = False
                if theme_filename not in enabled:
                    enabled.append(theme_filename)
                    data["enabledThemes"] = enabled
                    updated = True
                if not data.get("transparent", False):
                    data["transparent"] = True
                    updated = True
                if not data.get("frameless", False):
                    data["frameless"] = True
                    updated = True
                if not data.get("useQuickCss", False):
                    data["useQuickCss"] = True
                    updated = True
                if updated:
                    with open(s_path, "w", encoding="utf-8") as f:
                        json.dump(data, f, indent=4)
            except Exception as e:
                print(f"Notice enabling theme in {s_path}: {e}", file=sys.stderr)

def apply_fastfetch_theme(theme: dict, dynamic_accents: List[str]):
    # Fastfetch is configured to use terminal palette colors 1-5 for keys, 6 for title, and #ffffff for logo.
    pass

def apply_music_tui_theme(theme: dict, dynamic_accents: List[str]):
    sptlrx_config = os.path.expanduser("~/.config/sptlrx/config.yaml")
    accent = dynamic_accents[0] if dynamic_accents else theme["accent"]

    if os.path.isfile(sptlrx_config):
        try:
            with open(sptlrx_config, "r", encoding="utf-8") as f:
                content = f.read()

            pattern = r"(current\s*:\s*\n(?:\s{4}[^\n]+\n)*?\s{4}foreground\s*:\s*\")[^\"]*(\")"
            new_content = re.sub(pattern, rf"\g<1>{accent}\g<2>", content)

            with open(sptlrx_config, "w", encoding="utf-8") as f:
                f.write(new_content)
        except Exception as e:
            print(f"Notice applying sptlrx theme: {e}", file=sys.stderr)

def main():
    args = [arg for arg in sys.argv[1:] if not arg.startswith('-')]
    if not args:
        print("Usage: theme_matcher <wallpaper_path> [--dry-run]")
        sys.exit(1)

    wallpaper_path = os.path.abspath(os.path.expanduser(args[0]))
    dry_run = "--dry-run" in sys.argv

    try:
        target_image_path = wallpaper_path
        if is_video_file(wallpaper_path):
            print(f"Detected video wallpaper: {os.path.basename(wallpaper_path)}")
            print("Extracting representative frame using ffmpeg...")
            target_image_path = extract_video_frame(wallpaper_path)

        colors, mean_lum = extract_image_palette(target_image_path, max_colors=32)
        matched_key = match_theme(colors, mean_lum)
        theme = THEMES[matched_key]

        dynamic_accents = extract_wallpaper_accents(colors, theme["accent"], theme["border"])

        print(f"Matched Base Theme: {theme['name']} (Key: {matched_key})")
        print(f"Luminance: {mean_lum:.2f} -> Mode: {theme['type']}")
        print(f"Dynamic Wallpaper Accents: {', '.join(dynamic_accents)}")

        if not dry_run:
            apply_hyprland_theme(theme, dynamic_accents)
            apply_terminal_themes(theme, dynamic_accents)
            apply_shell_themes(theme, dynamic_accents)
            apply_fastfetch_theme(theme, dynamic_accents)
            apply_music_tui_theme(theme, dynamic_accents)
            # Automatically switch between mpvpaper (videos) and hyprpaper (images)
            apply_wallpaper_if_needed(wallpaper_path, fallback_frame_path=target_image_path)
            apply_pywal_cache(theme, target_image_path if is_video_file(wallpaper_path) else wallpaper_path, dynamic_accents)
            apply_vencord_theme(theme, dynamic_accents, wallpaper_path)
            notify_user(theme, dynamic_accents)
            print("Successfully applied dynamic theme, border gradients, terminals, shell, Vesktop/Vencord, Fastfetch, Music-TUI, and cache!")
    except Exception as e:
        print(f"Error matching theme: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()