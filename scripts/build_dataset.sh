#!/usr/bin/env bash
# NUR FÜR DEN DOZENTEN, einmalig: lädt Site-Archive von archive.org, extrahiert die
# benötigten XML-Dateien, konvertiert sie und packt dist/se-minimal.tar für das Release.
#
# Aufruf:  bash scripts/build_dataset.sh unix.stackexchange.com dba.stackexchange.com
#
# Wichtig: Sites immer VOLLSTÄNDIG übernehmen, nicht stichprobenartig kürzen.
# Eine Stichprobe erzeugt künstliche verwaiste Verweise und verfälscht Teil D.
set -euo pipefail
cd "$(dirname "$0")/.."

BASE_URL="${BASE_URL:-https://archive.org/download/stackexchange}"
[ $# -ge 1 ] || { echo "Aufruf: $0 <site.7z-Name ohne .7z> ..."; exit 1; }

command -v 7z >/dev/null || { sudo apt-get update -qq && sudo apt-get install -y -qq p7zip-full; }

mkdir -p raw dist
ARGS=()
{
  echo "Stack Exchange Data Dump, Quelle: $BASE_URL"
  echo "Lizenz: CC BY-SA 4.0, https://creativecommons.org/licenses/by-sa/4.0/"
  echo "Aufbereitet: $(date -u +%Y-%m-%d)"
  echo "Sites:"
} > raw/MANIFEST

for full in "$@"; do
  short="${full%%.*}"                # unix.stackexchange.com -> unix, askubuntu.com -> askubuntu
  if [ ! -f "raw/$full.7z" ]; then
    echo "== Lade $full.7z"
    curl -fL --retry 3 -o "raw/$full.7z" "$BASE_URL/$full.7z"
  fi
  echo "== Entpacke $full (ohne PostHistory und Badges)"
  mkdir -p "raw/$short"
  7z x -y -o"raw/$short" "raw/$full.7z" Users.xml Posts.xml Comments.xml Votes.xml PostLinks.xml Tags.xml >/dev/null
  echo "  $short = $full" >> raw/MANIFEST
  ARGS+=("$short=raw/$short")
done

echo "== Konvertiere"
rm -rf raw/csv && python3 scripts/convert_xml.py raw/csv "${ARGS[@]}"
cp raw/MANIFEST raw/csv/MANIFEST
tar -cf dist/se-minimal.tar -C raw/csv .
ls -lh dist/se-minimal.tar
echo
echo "Nächster Schritt: gh release create data-v1 dist/se-minimal.tar --title 'Datensatz v1' --notes-file raw/MANIFEST"
