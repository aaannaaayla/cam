#!/usr/bin/env bash
# setup-assets.sh — Downloads LUTs and sticker assets for the cam app.
# Run once from the repo root: bash scripts/setup-assets.sh
# Requires: curl, unzip

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LUTS_DIR="$REPO_ROOT/cam/Resources/LUTs"
STICKERS_DIR="$REPO_ROOT/cam/Resources/Stickers"
FONTS_DIR="$REPO_ROOT/cam/Resources/Fonts"

green()  { echo -e "\033[32m✓ $1\033[0m"; }
yellow() { echo -e "\033[33m→ $1\033[0m"; }
red()    { echo -e "\033[31m✗ $1\033[0m"; }

mkdir -p "$LUTS_DIR" "$STICKERS_DIR" "$FONTS_DIR"

# ─── LUTs ────────────────────────────────────────────────────────────────────

yellow "Downloading Film-Luts (MIT license)..."
TMP_FILM=$(mktemp -d)
curl -sL "https://github.com/YahiaAngelo/Film-Luts/archive/refs/heads/main.zip" -o "$TMP_FILM/film-luts.zip" && \
  unzip -q "$TMP_FILM/film-luts.zip" -d "$TMP_FILM" && \
  find "$TMP_FILM" -name "*.cube" -exec cp {} "$LUTS_DIR/" \; && \
  green "Film-Luts downloaded ($(find "$LUTS_DIR" -name '*.cube' | wc -l | tr -d ' ') .cube files so far)" || \
  red "Film-Luts download failed — check your internet connection"
rm -rf "$TMP_FILM"

yellow "Downloading lut-s (CC0 — public domain)..."
TMP_LUTS=$(mktemp -d)
curl -sL "https://github.com/cybars69/lut-s/archive/refs/heads/main.zip" -o "$TMP_LUTS/luts.zip" && \
  unzip -q "$TMP_LUTS/luts.zip" -d "$TMP_LUTS" && \
  find "$TMP_LUTS" -name "*.cube" -exec cp {} "$LUTS_DIR/" \; && \
  green "lut-s downloaded ($(find "$LUTS_DIR" -name '*.cube' | wc -l | tr -d ' ') .cube files total)" || \
  red "lut-s download failed"
rm -rf "$TMP_LUTS"

# ─── Noto Emoji stickers (Apache 2.0) ────────────────────────────────────────

yellow "Downloading Noto Emoji subset (Apache 2.0)..."

# We download a curated subset — not all 3700+ (that's ~150 MB).
# These codepoints cover Hearts, Stars, Nature, Expressions, Celebration, Food.
declare -A PACKS=(
  ["hearts"]="2764 1F495 1F496 1F497 1F498 1F499 1F49A 1F49B 1F49C 1F49D 1F9E1 1F90D 1F90E"
  ["stars"]="2B50 1F31F 1F4AB 2728 1F320 1F319 1F30C 1F308"
  ["nature"]="1F33A 1F33B 1F337 1F338 1F339 1F33C 1F33D 1F340 1F341 1F342 1F343 1F344 1F332 1F333"
  ["expressions"]="1F600 1F601 1F602 1F604 1F606 1F609 1F60A 1F60D 1F618 1F970 1F929 1F973 1F389 1F973"
  ["celebration"]="1F389 1F38A 1F38B 1F38C 1F38D 1F38E 1F38F 1F390 1F391 1F381 1F382 1F383"
  ["food"]="1F352 1F353 1F354 1F355 1F356 1F357 1F358 1F36A 1F36B 1F36C 1F370 1F382"
  ["baby"]="1F476 1F37C 1F9B8 1F9B9 1FAB6 1F6BC 1F9F8 1FAA6 1F97C 1F45F"
)

BASE_URL="https://raw.githubusercontent.com/googlefonts/noto-emoji/main/png/128"

for PACK_NAME in "${!PACKS[@]}"; do
  PACK_DIR="$STICKERS_DIR/$PACK_NAME"
  mkdir -p "$PACK_DIR"
  for CP in ${PACKS[$PACK_NAME]}; do
    # Noto Emoji filenames are lowercase hex: emoji_u1f600.png
    LOWER=$(echo "$CP" | tr '[:upper:]' '[:lower:]')
    URL="$BASE_URL/emoji_u${LOWER}.png"
    curl -sf "$URL" -o "$PACK_DIR/emoji_u${LOWER}.png" || true
  done
  COUNT=$(find "$PACK_DIR" -name "*.png" | wc -l | tr -d ' ')
  green "Pack '$PACK_NAME': $COUNT stickers"
done

# ─── Google Fonts (OFL 1.1) ──────────────────────────────────────────────────

yellow "Downloading Google Fonts..."

download_font() {
  local NAME="$1"
  local URL="$2"
  local OUT="$FONTS_DIR/${NAME}.ttf"
  curl -sL "$URL" -o "$OUT" && green "Font: $NAME" || red "Failed: $NAME"
}

# Direct download links for specific font files (stable GitHub raw URLs)
download_font "Caveat-Regular"    "https://github.com/googlefonts/caveat/raw/main/fonts/ttf/Caveat-Regular.ttf"
download_font "Caveat-Bold"       "https://github.com/googlefonts/caveat/raw/main/fonts/ttf/Caveat-Bold.ttf"
download_font "PlayfairDisplay-Regular" "https://github.com/googlefonts/playfair/raw/main/fonts/ttf/PlayfairDisplay-Regular.ttf"
download_font "PlayfairDisplay-Bold"    "https://github.com/googlefonts/playfair/raw/main/fonts/ttf/PlayfairDisplay-Bold.ttf"
download_font "DMSans-Regular"    "https://github.com/googlefonts/dm-fonts/raw/main/Sans/Fonts/Statics/DMSans-Regular.ttf"
download_font "DMSans-Bold"       "https://github.com/googlefonts/dm-fonts/raw/main/Sans/Fonts/Statics/DMSans-Bold.ttf"

# ─── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo "─────────────────────────────────────────"
green "Asset setup complete!"
echo ""
echo "  LUTs:     $(find "$LUTS_DIR"    -name '*.cube' | wc -l | tr -d ' ') .cube files in cam/Resources/LUTs/"
echo "  Stickers: $(find "$STICKERS_DIR" -name '*.png'  | wc -l | tr -d ' ') PNGs in cam/Resources/Stickers/"
echo "  Fonts:    $(find "$FONTS_DIR"   -name '*.ttf'   | wc -l | tr -d ' ') fonts in cam/Resources/Fonts/"
echo ""
echo "  Next: run 'xcodegen generate' to rebuild the .xcodeproj"
echo "  The new files will be picked up automatically."
echo "─────────────────────────────────────────"
