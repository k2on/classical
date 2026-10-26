# classical

Classical recordings that can be downloaded, with what they are: the
work, who wrote it and who played it, pictures and short descriptions. The
data is hand-written TOML, one file per thing; every push to `main` builds
it into one file,

    https://k2on.github.io/classical/catalogue.json

which is what [Harken](https://github.com/k2on/apps/tree/main/harken)
imports, and what its demo is made of.

## The files

- `people/<name>.toml`: one person — a composer or a performer, an orchestra
  or an ensemble the same. `name`, `sort_name`, `born`, `died`, `kinds`
  (`composer`, `pianist`, `violinist`, `conductor`, `orchestra`, `ensemble`,
  …), `art` (a portrait), `banner` (a wide picture for their page),
  `art_credit` and `banner_credit` (who made a picture and its licence, for
  one that asks to be credited) and `description`.
- `works/<composer>/<number>.toml`: one work, by the composer whose
  `people/<composer>.toml` its directory is named after. `catalogue` (`BWV
  988`, unique across all the works), `title`, `form`, `period`, `key_sig`,
  `composed` (a year) and `description`.
- `albums/<album>.toml`: an album's `name`, `art` and `year` (when it came
  out, or its recordings were made); its `[[performer]]`s,
  who played every track on it, each a person's `name`, their `role`
  (`orchestra`, `ensemble`, `conductor`, `soloist`, `artist`) and
  `instrument`, in billing order; and one `[[track]]` per track: `title`,
  `composer`, `part`, `track`, `catalogue`, `licence`, `bpm`, `ms` (its
  length) and `file` (where to download it). A track played by others than
  the album's names its own, as `[[track.performer]]`s after it.

A field nobody knows is left out. `nix build` makes `result`, the JSON;
`nix flake check` is what the push runs, and fails on a composer, performer
or work that has no file, a performer without a role, a name or catalogue
number used twice, or a URL that is not https.

## Licences

Every recording is public domain or under what its `licence` field names
(empty is public domain or no rights reserved), as its source says: a
licence, or for a recording that has none the copyright it is under. A
composer's or performer's `art` and `banner` are Apple Music's, where it
has them. The other pictures are mostly on Wikimedia Commons: public
domain, or under the licence their `art_credit` or `banner_credit` names;
an album's art may be its sleeve. The data itself — the files
here, descriptions included — is [CC0](LICENSE).
