#!/usr/bin/env bash
# Läuft einmal automatisch beim Erstellen des Codespace (postCreateCommand).
set -uo pipefail
cd "$(dirname "$0")/.."

echo "== 1/3 psql-Client 17 installieren (passend zur Serverversion)"
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -fsSL -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc \
     https://www.postgresql.org/media/keys/ACCC4CF8.asc
CODENAME=$(. /etc/os-release; echo "$VERSION_CODENAME")
echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" \
  | sudo tee /etc/apt/sources.list.d/pgdg.list >/dev/null
sudo apt-get update -qq && sudo apt-get install -y -qq postgresql-client-17 \
  || { echo "WARNUNG: PGDG nicht erreichbar, nehme Debian-Client"; sudo apt-get install -y -qq postgresql-client; }

echo "== 2/3 DuckDB-CLI installieren"
if curl -fsSL https://install.duckdb.org | sh >/dev/null 2>&1; then
  sudo ln -sf "$HOME/.duckdb/cli/latest/duckdb" /usr/local/bin/duckdb
  duckdb --version
else
  echo "WARNUNG: DuckDB-Installation fehlgeschlagen (für Termin 1 nicht nötig)"
fi

echo "== 3/3 Datensatz laden"
bash scripts/load_data.sh || echo "WARNUNG: Laden fehlgeschlagen. Erneut starten mit: bash scripts/load_data.sh"
