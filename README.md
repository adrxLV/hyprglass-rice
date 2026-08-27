# 🏝️ Tide Island — Hyprland + Apple LiquidGlass Rice

<div align="center">

![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-blue?style=for-the-badge&logo=archlinux)
![Quickshell](https://img.shields.io/badge/Quickshell-QML%20Qt6-8A2BE2?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Style](https://img.shields.io/badge/Design-Apple%20LiquidGlass-ff69b4?style=for-the-badge)

*A next-gen, glassmorphic desktop environment for Hyprland featuring interactive QML Dynamic Island widgets, real-time physical glass shaders, and dynamic wallpaper color auto-tematization.*

</div>

---

## 🎥 Preview & Demo

<div align="center">
  <video src="rec_20260813_001342.mp4" controls width="100%" poster="preview.jpg">
    Your browser does not support HTML5 video playback.
  </video>
  <p><i>Live demonstration of Tide Island Rice, Apple LiquidGlass shaders, and instant theme switching.</i></p>
</div>

---

## ✨ Features & Highlights

### 💎 Apple LiquidGlass Shader Engine (`hyprglass`)
- **Real-Time Physical Glass Shaders**: Custom glass surface rendering with light refraction, lens distortion, specular highlights, fresnel intensity, and chromatic aberration.
- **Adaptive Dimming & Depth Blur**: Dynamic window blurs, rounded corner geometries, and subtle ambient window borders.

### 🏝️ Tide Island QML Dynamic Suite
- **QML Dynamic Island Top Bar**: Interactive MacOS-inspired Dynamic Island developed natively in QML (`quickshell`).
- **Control & Notification Centers**: Integrated quick-toggles for Volume, Brightness, Bluetooth, Wi-Fi, and System Notifications.
- **Rich Media Player Widget**: Smooth album art blur animations, track seeking, and native `playerctl` integration.
- **Live Wallpaper & Theme Picker**: Choose wallpapers directly from an interactive GUI overlay.

### 🎨 Intelligent Auto-ColorScheme Applier (`theme_matcher.py`)
- **Color Extraction**: Analyzes chosen wallpaper images to compute primary, accent, and background palettes.
- **System-Wide Sync**: Automatically propagates palette shifts across **Hyprland**, **Kitty**, **Alacritty**, **Waybar**, **Cava**, **SwayNC**, and **Rofi** in real time (supporting *Gruvbox*, *Nord*, *Catppuccin*, *Everforest*, *Tokyo Night*, and more).

### 🛠️ Integrated `tide-*` Toolset
- `tide-calculator`: Instant pop-up overlay calculator.
- `tide-clipboard`: Visual clipboard history manager (`cliphist` + GUI).
- `tide-colorpicker`: Screen color sampler with `hyprpicker`.
- `tide-powermenu`: Sleek session menu (Lock, Suspend, Reboot, Shutdown).
- `tide-record`: One-click screen recorder (`wf-recorder`).
- `tide-screenshot-area` / `tide-screenshot-fullscreen`: Instant region/screen captures (`grim` + `slurp` + `wl-clipboard`).

---

## 📦 Required Programs & Dependencies

When using the included installer scripts (`install-rice.sh` or `setup.sh`), dependencies on Arch Linux / CachyOS are installed automatically!

- **Compositor**: [Hyprland](https://hyprland.org/)
- **UI & Widget Engine**: `quickshell-git` (Qt6 Declarative)
- **Terminals**: Kitty, Alacritty
- **Notification Daemon**: SwayNC
- **Wallpaper Engine**: Hyprpaper
- **Audio & Media**: Pipewire, Wireplumber, Playerctl, Pamixer, Brightnessctl, Cava
- **Utilities**: Grim, Slurp, Wl-clipboard, Cliphist, Wf-recorder, Rofi-Wayland
- **Customizations**: Spicetify-cli, Python (Pillow / PyGObject)

---

## 🔤 Fonts Used

- [JetBrains Mono Nerd Font](https://www.nerdfonts.com/font-downloads#jetbrainsmono)
- [Font Awesome](https://fontawesome.com/)
- [Noto Color Emoji](https://fonts.google.com/noto/specimen/Noto+Color+Emoji)

---

## ⚙️ Installation Guide

Follow these simple steps to install the complete rice environment on your system.

### 1. Clone the Repository

```bash
git clone https://github.com/adrxLV/hyprglass-rice.git
cd hyprglass-rice
```

### 2. Run the Installer

```bash
git clone https://github.com/adrxLV/hyprglass-rice.git
cd hyprglass-rice
chmod +x setup.sh
./setup.sh
```

---

## 🛡️ Safe Automated Backup

Your existing system setup is 100% protected!
Before applying any dotfiles, `setup.sh` creates a timestamped backup directory at:
```bash
~/.dotfiles_backup_YYYYMMDD_HHMMSS
```
All your previous configs in `~/.config`, `~/.local/share`, and `~/.local/bin` are backed up prior to installing the Tide Island suite.

---

## ⌨️ Keybindings Reference

All main shortcuts use the **Super (Windows)** key as the primary modifier.

### 🏝️ Tide Island & Dynamic Widgets
| Keybind | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>F</kbd> | Toggle / Expand Dynamic Island |
| <kbd>SUPER</kbd> + <kbd>D</kbd> | Application Launcher |
| <kbd>SUPER</kbd> + <kbd>W</kbd> | Live Wallpaper & Theme Switcher |
| <kbd>SUPER</kbd> + <kbd>C</kbd> | Toggle Control Center |
| <kbd>SUPER</kbd> + <kbd>N</kbd> | Toggle Notification Center |
| <kbd>SUPER</kbd> + <kbd>M</kbd> | Media Player Widget |
| <kbd>SUPER</kbd> + <kbd>Z</kbd> / <kbd>Print</kbd> | Screenshot & Recording Tools Menu |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>V</kbd> | Visual Clipboard History |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>C</kbd> | Quick Calculator Overlay |
| <kbd>SUPER</kbd> + <kbd>ALT</kbd> + <kbd>TAB</kbd> | Toggle Window Overview Mode |
| <kbd>SUPER</kbd> + <kbd>←</kbd> / <kbd>→</kbd> | Swipe / Navigate Dynamic Island Tabs |

### 🖥️ Application & System Shortcuts
| Keybind | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>Return</kbd> | Open Terminal (Kitty) |
| <kbd>SUPER</kbd> + <kbd>E</kbd> | Open File Manager (Dolphin) |
| <kbd>SUPER</kbd> + <kbd>Space</kbd> | Voice Agent Overlay |
| <kbd>SUPER</kbd> + <kbd>CTRL</kbd> + <kbd>Space</kbd> | Text Agent Overlay |
| <kbd>SUPER</kbd> + <kbd>Shift</kbd> + <kbd>E</kbd> / <kbd>SUPER</kbd> + <kbd>Escape</kbd> | Power Menu (Lock/Shutdown) |

### 🪟 Window Management
| Keybind | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>Q</kbd> | Close active window |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>Q</kbd> | Force kill active window |
| <kbd>SUPER</kbd> + <kbd>V</kbd> | Toggle floating mode |
| <kbd>SUPER</kbd> + <kbd>J</kbd> | Toggle split direction (dwindle) |
| <kbd>SUPER</kbd> + <kbd>LMB + Drag</kbd> | Move window |
| <kbd>SUPER</kbd> + <kbd>RMB + Drag</kbd> | Resize window |

### 🎯 Focus & Workspace Navigation
| Keybind | Action |
| :--- | :--- |
| <kbd>SUPER</kbd> + <kbd>← / → / ↑ / ↓</kbd> | Change window focus |
| <kbd>SUPER</kbd> + <kbd>1-9 / 0</kbd> | Switch to workspace 1-10 |
| <kbd>SUPER</kbd> + <kbd>SHIFT</kbd> + <kbd>1-9 / 0</kbd> | Move window to workspace 1-10 |
| <kbd>SUPER</kbd> + <kbd>Scroll Up / Down</kbd> | Switch adjacent workspaces |
| <kbd>SUPER</kbd> + <kbd>S</kbd> | Toggle Special Workspace (Scratchpad) |

---

## 📁 Repository Structure

```bash
hyprglass-rice/
├── README.md                 # Project documentation & guides
├── setup.sh                  # Core setup & dotfiles deployment script
├── dotfiles/                 # Uncompressed dotfiles (~/.config, ~/.local/share, ~/.local/bin)
└── wallpapers/               # Curated wallpaper collection for auto-theme matching
```

---

## 🔐 License

This project is licensed under the **MIT License**. Feel free to use, modify, and share!

<div align="center">
  <sub>Crafted with ❤️ for the Hyprland & Linux Ricing Community.</sub>
</div>
