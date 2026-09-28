SET client_min_messages = warning;
-- Stack-Exchange-Ausschnitt, mehrere Sites in einer Datenbank.
-- Ids sind nur innerhalb einer Site eindeutig: Schlüssel ist immer (site, id).
-- Bewusst KEINE Fremdschlüssel (Gegenstand von Termin 1, Teil E)
-- und keine Indexe außer den Primärschlüsseln (Gegenstand von Termin 2/3).
DROP TABLE IF EXISTS posts, users, comments, votes, post_links, tags CASCADE;

CREATE TABLE users (
  site              text     NOT NULL,
  id                integer  NOT NULL,
  reputation        integer,
  creation_date     timestamp,
  display_name      text,
  last_access_date  timestamp,
  location          text,
  about_me          text,
  views             integer,
  up_votes          integer,
  down_votes        integer,
  account_id        integer
);

CREATE TABLE posts (
  site                  text     NOT NULL,
  id                    integer  NOT NULL,
  post_type_id          smallint NOT NULL,   -- 1 Frage, 2 Antwort, weitere siehe Doku
  accepted_answer_id    integer,
  parent_id             integer,             -- bei Antworten: die Frage
  creation_date         timestamp,
  score                 integer,
  view_count            integer,
  body                  text,
  owner_user_id         integer,             -- NULL: Autor unbekannt (z. B. gelöschtes Konto)
  owner_display_name    text,
  last_editor_user_id   integer,
  last_edit_date        timestamp,
  last_activity_date    timestamp,
  title                 text,
  tags                  text,
  answer_count          integer,
  comment_count         integer,
  favorite_count        integer,
  closed_date           timestamp,
  community_owned_date  timestamp
);

CREATE TABLE comments (
  site               text     NOT NULL,
  id                 integer  NOT NULL,
  post_id            integer,
  score              integer,
  text               text,
  creation_date      timestamp,
  user_id            integer,
  user_display_name  text
);

CREATE TABLE votes (
  site           text     NOT NULL,
  id             integer  NOT NULL,
  post_id        integer,
  vote_type_id   smallint,
  user_id        integer,
  creation_date  timestamp,
  bounty_amount  integer
);

CREATE TABLE post_links (
  site             text     NOT NULL,
  id               integer  NOT NULL,
  creation_date    timestamp,
  post_id          integer,
  related_post_id  integer,
  link_type_id     smallint
);

CREATE TABLE tags (
  site              text     NOT NULL,
  id                integer  NOT NULL,
  tag_name          text,
  count             integer,
  excerpt_post_id   integer,
  wiki_post_id      integer
);
