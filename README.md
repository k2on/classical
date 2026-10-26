# classical

Classical recordings that are free to download, with what they are: the
work, who wrote it and who played it, pictures and short descriptions. The
data is hand-written TOML; every push to `main` builds it into one file,

    https://k2on.github.io/classical/catalogue.json

which is what [Harken](https://github.com/k2on/apps/tree/main/harken)
imports, and what its demo is made of.

## The files

- `people.toml`: one `[[person]]` per composer or performer. `name`,
  `sort_name`, `born`, `died`, `kinds` (`composer`, `pianist`, `violinist`,
  `conductor`, `orchestra`, `ensemble`, …), `art` (a portrait), `banner` (a
  wide picture for their page) and `description`.
- `works.toml`: one `[[work]]` per work. `composer`, `catalogue` (`BWV 988`,
  unique across the file), `title`, `form`, `period`, `key_sig`, `composed`
  (a year) and `description`.
- `credits.toml`: one `[[credit]]` per person on a recording, splitting the
  performer string a track carries into who did what: `performer` (as the
  tracks spell it), `name`, `role` (`orchestra`, `ensemble`, `conductor`,
  `soloist`, `artist`), `instrument` and `pos` (billing order).
- `albums/<album>.toml`: an album's `name` and `art`, and one `[[track]]` per
  track: `title`, `composer`, `part`, `track`, `catalogue`, `performer`,
  `licence`, `bpm`, `ms` (its length) and `file` (where to download it).

A field nobody knows is left out. `nix build` makes `result`, the JSON;
`nix flake check` is what the push runs, and fails on a composer or work
that is not in its file, a licence that is not public domain, CC0, CC BY or
CC BY-SA, or a URL that is not https.

## Licences

Every recording is public domain or under the licence its `licence` field
names (empty is public domain or no rights reserved), as its source says.
The pictures are public-domain images on Wikimedia Commons. The data
itself — the files here, descriptions included — is [CC0](LICENSE).
