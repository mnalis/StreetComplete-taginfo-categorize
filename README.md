## Prerequisites
- make, perl, JSON perl module, json_reformat (on Debian-based system: `apt-get install make perl libjson-perl yajl-tools`)
- `https://github.com/openstreetmap/id-tagging-schema` repository in `../id-tagging-schema`
- `https://github.com/streetcomplete/StreetComplete/` repository in `../StreetComplete`

## Usage instructions

Those scripts generate `KEYS_THAT_SHOULD_BE_REMOVED_WHEN_PLACE_IS_REPLACED` for the [StreetComplete](https://github.com/streetcomplete/StreetComplete) project.

`make update` should be run periodically, to find new keys with usage > 0.01%
and add them to `## TODO ##` section at the bottom of `keys.txt` file.

User should then investigate and move them from there to correct section
like `### KEYS TO REMOVE ###` or `### KEYS TO KEEP ###` sections of `keys.txt`.

Running `make` again will then generate `sc_to_remove.txt` with kotlin code to copy/paste to
https://github.com/streetcomplete/StreetComplete/blob/master/app/src/main/java/de/westnordost/streetcomplete/osm/Place.kt#L244
It is generated only from data in `### KEYS TO REMOVE ###` section.

If in doubt, `make distclean` will force next `make update` to refetch everything

## Notes on `keys.txt` format:

* each line can contain a regex (or normal text) representing key (in-line comments are possible too, as everything after `//` or `#` is ignored
* blank lines in `### KEYS TO REMOVE ###` section will become newlines in `sc_to_remove.txt`
* lines beginning with `//` in `### KEYS TO REMOVE ###` section will be copied to `sc_to_remove.txt`
* lines beginning with `#` are ignored completely

## when IS_PLACE_EXPRESSION in Place.kt changes

If [`IS_PLACE_EXPRESSION` in `Place.kt`](https://github.com/streetcomplete/StreetComplete/blob/master/app/src/main/java/de/westnordost/streetcomplete/osm/Place.kt#L34C13-L34C32)
changes (`make update` will warn you of that), then `FETCH_KEYS.make` / `FETCH_TAGS.make` should be updated too,
and scripts re-run (i.e. `make update` + `make`) in order to generate new
`KEYS_THAT_SHOULD_BE_REMOVED_WHEN_PLACE_IS_REPLACED` to put in `Place.kt`.

For example, if `IS_PLACE_EXPRESSION` was extended with:

```diff
+        or healthcare
+        or """ + mapOf(
+        "leisure" to listOf(
+            "adult_gaming_centre",
+            "amusement_arcade",
```

one would add `healthcare` to `FETCH_KEYS.make`, and `leisure=adult_gaming_centre leisure=amusement_arcade` to `FETCH_TAGS.make`

When one has completed updating `FETCH_KEYS.make` and `FETCH_TAGS.make`, they need to edit `Makefile` and update
`STREETCOMPLETE_LAST_GIT` at the top of it with git commit id that changed `Place.kt`, i.e. the one returned by:
```
cd $STREETCOMPLETE_PATH && git log -n 1 --format='%H' -- app/src/main/java/de/westnordost/streetcomplete/osm/Place.kt
```
