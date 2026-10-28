#!/usr/bin/env bash
# Hana Remix (はなリミックス): personalised Xubuntu 24.04 LTS live/installable ISO.
# Cubic-style remaster: download official Xubuntu minimal ISO, unpack its base squashfs,
# chroot + apt install extras, apply muted rose/sage theme, repack, rebuild ISO with the
# original boot setup (BIOS + UEFI).  Needs: Debian/Ubuntu host, sudo, ~20 GB free.
#   sudo apt install xorriso squashfs-tools curl
#   ./build.sh            -> out/hana-remix-24.04-amd64.iso
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${WORK:-$HERE/work}"; OUT="${OUT:-$HERE/out}"; CACHE="${CACHE:-$HERE/cache}"
BASE_URL="https://cdimage.ubuntu.com/xubuntu/releases/24.04/release"
ISO_NAME="xubuntu-24.04.5-minimal-amd64.iso"
BASE="$CACHE/$ISO_NAME"
mkdir -p "$WORK" "$OUT" "$CACHE"

if [ ! -s "$BASE" ]; then
  curl -fL -o "$BASE.part" "$BASE_URL/$ISO_NAME" && mv "$BASE.part" "$BASE"
fi
( cd "$CACHE" && curl -fsSL "$BASE_URL/SHA256SUMS" | grep " \*\?$ISO_NAME\$" | sed 's/\*//' | sha256sum -c - ) \
  || { echo "Checksum failed"; exit 1; }

echo "== unpack"
sudo rm -rf "$WORK/root"; mkdir -p "$WORK"
xorriso -osirrox on -indev "$BASE" -extract /casper/minimal.squashfs "$WORK/minimal.squashfs" 2>/dev/null
sudo unsquashfs -q -d "$WORK/root" "$WORK/minimal.squashfs"
R="$WORK/root"

echo "== chroot install"
for d in dev dev/pts proc sys run; do sudo mount --bind /$d "$R/$d"; done
cleanup(){ for d in run sys proc dev/pts dev; do sudo umount -l "$R/$d" 2>/dev/null || true; done; }
trap cleanup EXIT
sudo cp /etc/resolv.conf "$R/etc/resolv.conf.remix"; sudo mount --bind /etc/resolv.conf "$R/etc/resolv.conf" 2>/dev/null || true
sudo chroot "$R" /bin/bash -euxc '
  export DEBIAN_FRONTEND=noninteractive
  # Firefox as a real .deb from Mozilla (Ubuntu ships it as a snap, which cannot install in a chroot)
  apt-get update; apt-get install -y wget ca-certificates
  install -d -m 0755 /etc/apt/keyrings
  wget -qO /etc/apt/keyrings/packages.mozilla.org.asc https://packages.mozilla.org/apt/repo-signing-key.gpg
  echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list
  printf "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n" > /etc/apt/preferences.d/mozilla
  apt-get update
  apt-get install -y --no-install-recommends \
    fcitx5 fcitx5-mozc fcitx5-config-qt fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt5 im-config \
    fonts-noto-cjk fonts-noto-color-emoji language-pack-ja language-pack-gnome-ja \
    vlc firefox firefox-l10n-ja ristretto mousepad galculator xfce4-screenshooter
  apt-get clean; rm -rf /var/lib/apt/lists/*
'
sudo umount -l "$R/etc/resolv.conf" 2>/dev/null || true; sudo rm -f "$R/etc/resolv.conf.remix"

echo "== overlay (theme, shortcuts, input)"
# Images are kept in git as base64 text (*.png.b64); turn them back into PNGs
for b in $(find "$HERE/overlay" -name '*.png.b64'); do [ -f "${b%.b64}" ] || base64 -d "$b" > "${b%.b64}"; done
sudo cp -r --no-preserve=ownership "$HERE/overlay/." "$R/"
sudo find "$R/usr/share" -name '*.png.b64' -delete
sudo chroot "$R" /bin/bash -c 'chmod +x /usr/local/bin/hana-* 2>/dev/null; glib-compile-schemas /usr/share/glib-2.0/schemas >/dev/null 2>&1 || true; update-desktop-database -q || true; im-config -n fcitx5 || true'
cleanup; trap - EXIT

echo "== repack"
rm -f "$WORK/new.squashfs"
sudo mksquashfs "$R" "$WORK/new.squashfs" -comp xz -b 1M -noappend -quiet
SIZE=$(sudo du -sx --block-size=1 "$R" | cut -f1)
echo "$SIZE" > "$WORK/minimal.size"
sudo chroot "$R" dpkg-query -W --showformat='${Package} ${Version}\n' > "$WORK/minimal.manifest"
ISO="$OUT/hana-remix-24.04-amd64.iso"; rm -f "$ISO"
xorriso -indev "$BASE" -outdev "$ISO" \
  -map "$WORK/new.squashfs" /casper/minimal.squashfs \
  -map "$WORK/minimal.size" /casper/minimal.size \
  -map "$WORK/minimal.manifest" /casper/minimal.manifest \
  -rm /casper/SHA256SUMS /casper/SHA256SUMS.gpg -- \
  -volid "Hana Remix 24.04" \
  -boot_image any replay
sha256sum "$ISO" | tee "$ISO.sha256"
echo "Done: $ISO"
