#!/usr/bin/env python3
"""Stack-Exchange-XML -> CSV.gz (eine Datei je Tabelle, alle Sites zusammen).

Aufruf: convert_xml.py <ausgabeverzeichnis> <site>=<xml-verzeichnis> [<site>=<xml-verzeichnis> ...]
Beispiel: convert_xml.py data unix=raw/unix dba=raw/dba
Nur Standardbibliothek; streamt, braucht also kaum Speicher.
"""
import csv, gzip, sys, os
import xml.etree.ElementTree as ET

TABLES = {
    "Users": ("users", ["Id", "Reputation", "CreationDate", "DisplayName", "LastAccessDate",
                        "Location", "AboutMe", "Views", "UpVotes", "DownVotes", "AccountId"]),
    "Posts": ("posts", ["Id", "PostTypeId", "AcceptedAnswerId", "ParentId", "CreationDate", "Score",
                        "ViewCount", "Body", "OwnerUserId", "OwnerDisplayName", "LastEditorUserId",
                        "LastEditDate", "LastActivityDate", "Title", "Tags", "AnswerCount",
                        "CommentCount", "FavoriteCount", "ClosedDate", "CommunityOwnedDate"]),
    "Comments": ("comments", ["Id", "PostId", "Score", "Text", "CreationDate", "UserId", "UserDisplayName"]),
    "Votes": ("votes", ["Id", "PostId", "VoteTypeId", "UserId", "CreationDate", "BountyAmount"]),
    "PostLinks": ("post_links", ["Id", "CreationDate", "PostId", "RelatedPostId", "LinkTypeId"]),
    "Tags": ("tags", ["Id", "TagName", "Count", "ExcerptPostId", "WikiPostId"]),
}

def snake(name):
    out = ""
    for i, c in enumerate(name):
        if c.isupper() and i > 0:
            out += "_"
        out += c.lower()
    return out

def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    outdir = sys.argv[1]
    sites = [a.split("=", 1) for a in sys.argv[2:]]
    os.makedirs(outdir, exist_ok=True)
    for xmlname, (table, attrs) in TABLES.items():
        path = os.path.join(outdir, f"{table}.csv.gz")
        with gzip.open(path, "wt", newline="", encoding="utf-8") as f:
            w = csv.writer(f)
            w.writerow(["site"] + [snake(a) for a in attrs])
            for site, xmldir in sites:
                src = os.path.join(xmldir, f"{xmlname}.xml")
                n = 0
                for _, el in ET.iterparse(src, events=("end",)):
                    if el.tag == "row":
                        # fehlendes Attribut -> leeres, unquotiertes Feld -> NULL in PostgreSQL
                        w.writerow([site] + [el.get(a) for a in attrs])
                        n += 1
                    el.clear()
                print(f"{table:<11} {site:<10} {n:>10} Zeilen", flush=True)
    print("fertig:", outdir)

if __name__ == "__main__":
    main()
