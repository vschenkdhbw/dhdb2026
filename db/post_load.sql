ALTER TABLE users      ADD PRIMARY KEY (site, id);
ALTER TABLE posts      ADD PRIMARY KEY (site, id);
ALTER TABLE comments   ADD PRIMARY KEY (site, id);
ALTER TABLE votes      ADD PRIMARY KEY (site, id);
ALTER TABLE post_links ADD PRIMARY KEY (site, id);
ALTER TABLE tags       ADD PRIMARY KEY (site, id);
ANALYZE;
