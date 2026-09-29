#!/usr/bin/env bash
# Termin 2: Umgebung vorbereiten.
# Aufruf im Projektverzeichnis:  scripts/termin2.sh
# Kann beliebig oft ausgeführt werden; jeder Lauf stellt den Ausgangszustand her.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "1/3 PostgreSQL einstellen ..."
psql -q <<'SQL'
-- Einfachere Pläne: keine parallelen Teilprozesse, keine JIT-Zeilen
ALTER DATABASE stackexchange SET max_parallel_workers_per_gather = 0;
ALTER DATABASE stackexchange SET jit = off;
-- Ausgangszustand: nur die Primärschlüssel, keine Indexe aus früheren Versuchen
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT i.indexrelid::regclass AS idx
    FROM pg_index i
    JOIN pg_class c ON c.oid = i.indrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND NOT EXISTS (SELECT 1 FROM pg_constraint k WHERE k.conindid = i.indexrelid)
  LOOP
    EXECUTE 'DROP INDEX ' || r.idx;
  END LOOP;
END $$;
DROP TABLE IF EXISTS wv;
DROP TABLE IF EXISTS stimmen;
SQL

echo "2/3 DuckDB vorbereiten ..."
duckdb -c "INSTALL postgres;" > /dev/null

echo "3/3 posts nach DuckDB kopieren (dauert 1 bis 2 Minuten) ..."
rm -f se.duckdb se.duckdb.wal
duckdb se.duckdb <<'DUCK' > /dev/null
LOAD postgres;
ATTACH 'dbname=stackexchange' AS pg (TYPE postgres, READ_ONLY);
CREATE TABLE posts AS SELECT * FROM pg.posts;
DUCK

echo
echo "Kontrolle:"
echo -n "  Parallelität in PostgreSQL (erwartet 0): "
psql -Atc "SHOW max_parallel_workers_per_gather;"
echo -n "  JIT (erwartet off): "
psql -Atc "SHOW jit;"
echo -n "  Zusätzliche Indexe (erwartet 0): "
psql -Atc "SELECT count(*) FROM pg_indexes WHERE schemaname = 'public' AND indexname NOT LIKE '%pkey';"
echo -n "  Zeilen in DuckDB (erwartet 836948): "
duckdb se.duckdb -noheader -list -c "SELECT count(*) FROM posts;"
echo
echo "Fertig. Jetzt: psql starten und \\timing on."