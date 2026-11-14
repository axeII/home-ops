#!/bin/sh
# Copies each library entry's cover from Suwayomi's thumbnail cache into its
# download folder as cover.<ext>. Komga uses that file as the series poster;
# without it Komga shows the first page of the first chapter, which for a
# webtoon is one tall strip. An existing cover.* is never overwritten.
set -u

API="${SUWAYOMI_API:-http://localhost:4567/api/graphql}"
ROOT="${DOWNLOADS_DIR:-/downloads}"
INTERVAL="${INTERVAL_SECONDS:-900}"
QUERY='{"query":"{ mangas(condition: {inLibrary: true}) { nodes { id title source { displayName } } } }"}'
TAB="$(printf '\t')"

# "safe" mirrors Suwayomi's SafePath.buildValidFilename, which names the
# download folders: trim dots and spaces, then replace characters that are
# invalid on FAT with "_". After it no tab or newline is left, so the fields
# can be read back line by line.
# shellcheck disable=SC2016
ROWS='def safe: sub("^[. ]+"; "") | sub("[. ]+$"; "") | gsub("[\"*/:<>?\\\\|[:cntrl:]]"; "_");
  .data.mangas.nodes[] | "\(.id)\t\(.source.displayName | safe)\t\(.title | safe)"'

sync_covers() {
  resp="$(curl -fsS -m 30 -H 'Content-Type: application/json' -d "$QUERY" "$API")" || {
    echo "Suwayomi API not reachable, retrying later"
    return 0
  }
  printf '%s' "$resp" | jq -r "$ROWS" |
    while IFS="$TAB" read -r id source title; do
      dir="$ROOT/mangas/$source/$title"
      [ -d "$dir" ] || continue
      for existing in "$dir"/cover.*; do
        [ -e "$existing" ] && continue 2
      done
      for thumb in "$ROOT/thumbnails/$id".*; do
        [ -f "$thumb" ] || continue
        cp "$thumb" "$dir/cover.${thumb##*.}" && echo "cover added: $dir"
        break
      done
    done
}

while true; do
  sync_covers
  [ -n "${RUN_ONCE:-}" ] && exit 0
  sleep "$INTERVAL"
done
