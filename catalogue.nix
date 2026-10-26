# The catalogue as one JSON document, from the TOML beside this file: one
# file per person (people/), per work (works/<composer>/, the directory
# naming its composer's file in people/) and per album (albums/). A field
# left out is empty ("", 0 or []), so the files say only what is known.
# What the files get wrong fails the build, with a message saying what.
let
  read = file: builtins.fromTOML (builtins.readFile file);
  fill = defaults: entry: defaults // entry;
  # A directory's .toml files, by their names without it, and its
  # directories.
  tomls =
    dir:
    map (n: builtins.substring 0 (builtins.stringLength n - 5) n) (
      builtins.filter (n: builtins.match ".*\\.toml" n != null) (builtins.attrNames (builtins.readDir dir))
    );
  dirs =
    dir:
    let
      entries = builtins.readDir dir;
    in
    builtins.filter (n: entries.${n} == "directory") (builtins.attrNames entries);

  # Composers and performers alike: whoever a work or a track names.
  people = map (
    slug:
    fill {
      sort_name = "";
      born = 0;
      died = 0;
      # composer, pianist, violinist, conductor, orchestra, ensemble, ...
      kinds = [ ];
      art = "";
      banner = "";
      # Who made a picture and under what licence, for one that asks it.
      art_credit = "";
      banner_credit = "";
      description = "";
    } (read (./people + "/${slug}.toml"))
    // {
      inherit slug;
    }
  ) (tomls ./people);
  bySlug = builtins.listToAttrs (map (p: { name = p.slug; value = p; }) people);

  works = builtins.concatMap (
    composer:
    map (
      n:
      fill {
        catalogue = "";
        form = "";
        period = "";
        key_sig = "";
        composed = 0;
        description = "";
      } (read (./works + "/${composer}/${n}.toml"))
      // {
        composer = (bySlug.${composer} or (throw "works/${composer}: there is no people/${composer}.toml")).name;
      }
    ) (tomls (./works + "/${composer}"))
  ) (dirs ./works);

  track =
    performers:
    fill {
      part = "";
      track = 0;
      catalogue = "";
      # Who played it, in billing order: the album's, unless the track
      # names its own.
      performer = performers;
      # Empty for public domain or no rights reserved; otherwise the licence
      # the recording asks to be credited under, or the copyright it is
      # under, drawn beside its performer.
      licence = "";
      bpm = 0;
    };
  albums = map (
    n:
    let
      a = read (./albums + "/${n}.toml");
    in
    {
      name = a.name or (throw "albums/${n}: no name");
      art = a.art or "";
      # The year it came out, or its recordings were made; 0 for not known.
      year = a.year or 0;
      tracks = map (track (a.performer or [ ])) (a.track or (throw "albums/${n}: no tracks"));
    }
  ) (tomls ./albums);

  tracks = builtins.concatMap (a: map (t: t // { album = a.name; }) a.tracks) albums;
  # A track's people as the one string a track carries (its tag's
  # "performer"), and the credits that string is of: one per person, once.
  billed = t: builtins.concatStringsSep ", " (map (c: c.name) t.performer);
  credits = builtins.attrValues (
    builtins.listToAttrs (
      builtins.concatMap (
        t:
        builtins.genList (
          i:
          let
            c = { instrument = ""; } // builtins.elemAt t.performer i;
          in
          {
            name = "${billed t}/${toString i}";
            value = {
              performer = billed t;
              inherit (c) name role instrument;
              pos = i + 1;
            };
          }
        ) (builtins.length t.performer)
      ) tracks
    )
  );

  # Checks: a reference that does not resolve is a mistake in the files.
  names = map (p: p.name) people;
  catalogues = map (w: w.catalogue) (builtins.filter (w: w.catalogue != "") works);
  has = list: x: builtins.elem x list;
  https = u: u == "" || builtins.match "https://.*" u != null;
  unique =
    l:
    builtins.length l
    == builtins.length (builtins.attrNames (builtins.listToAttrs (map (x: { name = x; value = null; }) l)));
  check =
    what: ok: msg:
    if ok then [ ] else [ "${what}: ${msg}" ];
  problems =
    builtins.concatMap (
      t:
      let
        what = "${t.album} / ${t.title}";
      in
      check what (has names t.composer) "composer ${t.composer} is not in people/"
      ++ check what (t.catalogue == "" || has catalogues t.catalogue) "${t.catalogue} is not in works/"
      ++ check what (builtins.match "https://.*" t.file != null) "file is not an https URL"
      ++ check what (t.ms > 0) "no duration (ms)"
      ++ builtins.concatMap (
        c:
        check what (has names (c.name or "")) "performer ${c.name or "?"} is not in people/"
        ++ check what ((c.role or "") != "") "performer ${c.name or "?"} has no role"
      ) t.performer
    ) tracks
    ++ builtins.concatMap (
      p: check "people/${p.slug}" (https p.art && https p.banner) "art and banner are https URLs"
    ) people
    ++ builtins.concatMap (a: check a.name (https a.art) "art is not an https URL") albums
    ++ builtins.concatMap (a: check a.name (builtins.isInt a.year) "year is not a number") albums
    ++ check "people/" (unique names) "a name is used twice"
    ++ check "works/" (unique catalogues) "a catalogue number is used twice";
in
if problems != [ ] then
  throw "the catalogue has mistakes:\n  ${builtins.concatStringsSep "\n  " problems}"
else
  builtins.toJSON {
    version = 1;
    people = map (p: builtins.removeAttrs p [ "slug" ]) people;
    inherit works credits;
    albums = map (a: a // { tracks = map (t: t // { performer = billed t; }) a.tracks; }) albums;
  }
