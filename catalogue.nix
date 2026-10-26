# The catalogue as one JSON document, from the TOML beside this file:
# people.toml, works.toml, credits.toml and one albums/*.toml per album. A
# field left out is empty ("", 0 or []), so the files say only what is known.
# What the files get wrong fails the build, with a message saying what.
let
  read = file: builtins.fromTOML (builtins.readFile file);
  fill = defaults: entry: defaults // entry;

  people = map (fill {
    sort_name = "";
    born = 0;
    died = 0;
    # composer, pianist, violinist, conductor, orchestra, ensemble, singer...
    kinds = [ ];
    art = "";
    banner = "";
    description = "";
  }) ((read ./people.toml).person or [ ]);

  works = map (fill {
    catalogue = "";
    form = "";
    period = "";
    key_sig = "";
    composed = 0;
    description = "";
  }) ((read ./works.toml).work or [ ]);

  credits = map (fill { instrument = ""; }) ((read ./credits.toml).credit or [ ]);

  track = fill {
    part = "";
    track = 0;
    catalogue = "";
    performer = "";
    # Empty for public domain or no rights reserved; otherwise the licence
    # the recording asks to be credited under, drawn beside its performer.
    licence = "";
    bpm = 0;
  };
  albumFiles = builtins.filter (n: builtins.match ".*\\.toml" n != null) (
    builtins.attrNames (builtins.readDir ./albums)
  );
  albums = map (
    n:
    let
      a = read (./albums + "/${n}");
    in
    {
      name = a.name or (throw "albums/${n}: no name");
      art = a.art or "";
      tracks = map track (a.track or (throw "albums/${n}: no tracks"));
    }
  ) albumFiles;

  tracks = builtins.concatMap (a: map (t: t // { album = a.name; }) a.tracks) albums;

  # Checks: a reference that does not resolve or a licence that is not one
  # of these is a mistake in the files.
  licences = "(CC0 1\\.0|CC BY [0-9.]+|CC BY-SA [0-9.]+)?";
  names = map (p: p.name) people;
  catalogues = map (w: w.catalogue) (builtins.filter (w: w.catalogue != "") works);
  performers = map (t: t.performer) tracks;
  has = list: x: builtins.elem x list;
  https = u: u == "" || builtins.match "https://.*" u != null;
  check =
    what: ok: msg:
    if ok then [ ] else [ "${what}: ${msg}" ];
  problems =
    builtins.concatMap (
      t:
      let
        what = "${t.album} / ${t.title}";
      in
      check what (has names t.composer) "composer ${t.composer} is not in people.toml"
      ++ check what (t.catalogue == "" || has catalogues t.catalogue) "${t.catalogue} is not in works.toml"
      ++ check what (builtins.match licences t.licence != null) "licence \"${t.licence}\" is not CC0 1.0, CC BY or CC BY-SA"
      ++ check what (builtins.match "https://.*" t.file != null) "file is not an https URL"
      ++ check what (t.ms > 0) "no duration (ms)"
    ) tracks
    ++ builtins.concatMap (
      w: check w.title (has names w.composer) "composer ${w.composer} is not in people.toml"
    ) works
    ++ builtins.concatMap (
      c: check c.name (has performers c.performer) "performer \"${c.performer}\" is on no track"
    ) credits
    ++ builtins.concatMap (
      p: check p.name (https p.art && https p.banner) "art and banner are https URLs"
    ) people
    ++ builtins.concatMap (a: check a.name (https a.art) "art is not an https URL") albums
    ++ check "works.toml" (builtins.length catalogues == builtins.length (
      builtins.attrNames (builtins.listToAttrs (map (c: { name = c; value = null; }) catalogues))
    )) "a catalogue number is used twice";
in
if problems != [ ] then
  throw "the catalogue has mistakes:\n  ${builtins.concatStringsSep "\n  " problems}"
else
  builtins.toJSON {
    version = 1;
    inherit
      people
      works
      credits
      albums
      ;
  }
