#!/usr/bin/env bash
# Lädt den aufbereiteten Datensatz (Release-Asset) in PostgreSQL.
# Idempotent: kann jederzeit erneut ausgeführt werden und setzt die DB auf den Ausgangszustand zurück.
set -euo pipefail
cd "$(dirname "$0")/.."

DATA_TAG="${DATA_TAG:-data-v1}"
ASSET="${ASSET:-se-minimal.tar}"
DATA_DIR="data"
SERVER_DATA_DIR="${SERVER_DATA_DIR:-/repo/data}"   # derselbe Ordner aus Sicht des db-Containers

REPO="${GITHUB_REPOSITORY:-}"
if [ -z "$REPO" ]; then
  REPO=$(git remote get-url origin | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')
fi
URL="https://github.com/${REPO}/releases/download/${DATA_TAG}/${ASSET}"

mkdir -p "$DATA_DIR"
if [ ! -f "$DATA_DIR/MANIFEST" ]; then
  echo "Lade $URL"
  if ! curl -fL --retry 3 -o "/tmp/$ASSET" "$URL"; then
    echo "FEHLER: Datensatz nicht gefunden. Existiert das Release '$DATA_TAG' mit '$ASSET'?"
    exit 1
  fi
  tar -xf "/tmp/$ASSET" -C "$DATA_DIR" && rm -f "/tmp/$ASSET"
fi

echo "Warte auf PostgreSQL ..."
for i in $(seq 1 60); do pg_isready -q && break; sleep 1; done

psql -q -v ON_ERROR_STOP=1 -f db/schema.sql
# Serverseitiges COPY statt psql-\copy: psql bricht bei einer Datenzeile "\." ab
# (Ende-Markierung des COPY-Protokolls), auch innerhalb eines CSV-Feldes.
for t in users posts comments votes post_links tags; do
  echo "  COPY $t"
  psql -q -v ON_ERROR_STOP=1 -c "COPY $t FROM PROGRAM 'gzip -dc $SERVER_DATA_DIR/$t.csv.gz' WITH (FORMAT csv, HEADER true)"
done
echo "Primärschlüssel und Statistiken ..."
psql -q -v ON_ERROR_STOP=1 -f db/post_load.sql

echo
cat "$DATA_DIR/MANIFEST"
psql -c "SELECT site, count(*) AS posts FROM posts GROUP BY site ORDER BY site;"
echo "Fertig. Verbinden mit: psql"
