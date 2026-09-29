#!/usr/bin/env bash
# Termin 2: Umgebung vorbereiten.
# Aufruf im Projektverzeichnis:  scripts/termin2.sh
# Kann beliebig oft ausgeführt werden; jeder Lauf stellt den Ausgangszustand her.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "1/3 PostgreSQL einstellen ..."
psql -q <<'SQL'
-- Einfachere Pläne: keine parallelen Teilprozesse
ALTER DATABASE stackexchange SET max_parallel_workers_per_gather = 0;
-- Ausgangszustand: nur die Primärschlüssel, keine Indexe aus früheren Versuchen
DROP INDEX IF EXISTS posts_parent, posts_datum, posts_score, posts_titel,
                     posts_titel_muster, posts_titel_trgm, comments_post;
DROP TABLE IF EXISTS wv;
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
echo -n "  Parallelität in PostgreSQL: "
psql -Atc "SHOW max_parallel_workers_per_gather;"
echo -n "  Zusätzliche Indexe auf posts/comments: "
psql -Atc "SELECT count(*) FROM pg_indexes WHERE tablename IN ('posts','comments') AND indexname NOT LIKE '%pkey';"
echo -n "  Zeilen in DuckDB (erwartet 836948): "
duckdb se.duckdb -noheader -list -c "SELECT count(*) FROM posts;"
echo
echo "Fertig. Jetzt: psql starten und \\timing on."
