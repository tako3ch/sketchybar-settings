#!/bin/bash

ARTWORK_DIR="$HOME/.cache/sketchybar"
ARTWORK="$ARTWORK_DIR/spotify-cover.jpg"
ARTWORK_URL_FILE="$ARTWORK_DIR/spotify-cover.url"
mkdir -p "$ARTWORK_DIR"

# scale / color / size / padding / corner_radius は sketchybarrc 側の値を尊重する。

cover_item_exists() {
  sketchybar --query spotify_cover >/dev/null 2>&1
}

hide_cover() {
  if cover_item_exists; then
    sketchybar --set spotify_cover drawing=off background.image.drawing=off
  fi
}

hide_spotify() {
  sketchybar --set spotify drawing=off
  hide_cover
}

show_cover() {
  if ! cover_item_exists; then
    return
  fi
  if [[ -s "$ARTWORK" ]]; then
    sketchybar --set spotify_cover \
      drawing=on \
      background.drawing=on \
      background.image="$ARTWORK" \
      background.image.drawing=on
  else
    sketchybar --set spotify_cover \
      drawing=on \
      background.drawing=on \
      background.image.drawing=off
  fi
}

if ! pgrep -x Spotify >/dev/null; then
  hide_spotify
  exit 0
fi

state=$(osascript -e 'tell application "Spotify" to player state as string' 2>/dev/null)
if [[ "$state" != "playing" && "$state" != "paused" ]]; then
  hide_spotify
  exit 0
fi

track=$(osascript -e 'tell application "Spotify" to name of current track as string' 2>/dev/null)
artist=$(osascript -e 'tell application "Spotify" to artist of current track as string' 2>/dev/null)
artwork_url=$(osascript -e 'tell application "Spotify" to artwork url of current track as string' 2>/dev/null)
if [[ -z "$track" ]]; then
  hide_spotify
  exit 0
fi

# Download only when the track's artwork URL changes.
# 失敗しても既存ファイルがあれば表示を維持する。
if [[ -n "$artwork_url" ]]; then
  cached_url=""
  [[ -f "$ARTWORK_URL_FILE" ]] && cached_url=$(<"$ARTWORK_URL_FILE")
  if [[ "$artwork_url" != "$cached_url" || ! -s "$ARTWORK" ]]; then
    tmp="$ARTWORK.tmp"
    if /usr/bin/curl -fsSL --max-time 10 "$artwork_url" -o "$tmp" && mv -f "$tmp" "$ARTWORK"; then
      printf '%s' "$artwork_url" > "$ARTWORK_URL_FILE"
    else
      rm -f "$tmp"
    fi
  fi
fi

icon="▶"
if [[ "$state" == "paused" ]]; then
  icon="Ⅱ"
fi

text="$artist — $track"
max=42
if (( ${#text} > max )); then
  text="${text:0:max}…"
fi

sketchybar --set spotify \
  drawing=on \
  icon.drawing=on \
  icon="$icon" \
  label="$text"

show_cover
