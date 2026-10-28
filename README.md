# Hana Remix 24.04 (Ubuntu / Xubuntu remix)

A gentle, ready-to-use Xubuntu 24.04 for the family: soft rose & sage look, Japanese out of the box,
and big friendly shortcuts. No ads, no accounts.

## What's inside
- Base: official **Xubuntu 24.04.5 minimal** ISO (checksum verified at build time)
- 日本語入力 Japanese input: **fcitx5 + Mozc** (switch with 半角/全角 or Ctrl+Space), Noto CJK fonts, Japanese language packs
- **Firefox** (real .deb from Mozilla, not a snap) with Japanese language pack
- **VLC** for videos and music, image viewer, text editor, calculator, screenshot tool
- Desktop shortcuts: **Free Apps** (gutsmcd-cmd.github.io/free-apps) and **Universe 74**
- Rose panel, rose/sage wallpaper, Noto Sans CJK JP font (set once per user on first login)

## Build (on Ubuntu/Debian, ~15 GB free space, sudo)
```
sudo apt install squashfs-tools xorriso wget
./build.sh            # writes remix/hana-remix-24.04-amd64.iso + .sha256
```
Images in `overlay/` are stored as base64 text (`*.png.b64`); build.sh decodes them.

## Put it on a USB stick
Use [balenaEtcher](https://etcher.balena.io/) or Rufus (Windows, "DD mode"), choose the ISO, flash.
Boot from USB → "Try or Install" → use the **Install Xubuntu** icon on the desktop to install.

## Tested
Built and booted in QEMU (live session reaches the themed desktop with the shortcuts).
Not yet tested: installing to a real disk, real hardware.
