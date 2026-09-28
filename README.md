# Datenbanksysteme II (T4INF3103), WS 2026/27: Laborumgebung (Minimal)

PostgreSQL 17 (mit pgvector) und DuckDB in GitHub Codespaces, vorgeladen mit einem
Ausschnitt des Stack-Exchange-Datensatzes (mehrere Sites in einer Datenbank).

## Start

1. Oben rechts **Code → Codespaces → Create codespace on main** (oder den Link aus Moodle).
2. Warten, bis im Terminal „Fertig. Verbinden mit: psql“ steht (beim ersten Start einige Minuten).
3. Im Terminal: `psql`

Nützlich in psql: `\dt` (Tabellen), `\d posts` (Spalten), `\x` (Ausgabe umschalten), `\q` (Ende).

## Datenmodell in einem Satz

Tabellen `posts`, `users`, `comments`, `votes`, `post_links`, `tags`; jede Zeile trägt `site`.
**Ids sind nur innerhalb einer Site eindeutig**, der Schlüssel ist immer `(site, id)`.

## Zurücksetzen

`bash scripts/load_data.sh` stellt den Ausgangszustand wieder her.

## Nach dem Termin

Codespace **stoppen** (Codespaces-Liste → … → Stop codespace), nicht löschen.
Laufende Codespaces verbrauchen das freie Kontingent.

## Quelle und Lizenz der Daten

Stack Exchange Data Dump, https://archive.org/details/stackexchange,
Inhalte der Stack-Exchange-Community unter CC BY-SA 4.0
(https://creativecommons.org/licenses/by-sa/4.0/). Welche Sites enthalten sind, steht in `data/MANIFEST`.
