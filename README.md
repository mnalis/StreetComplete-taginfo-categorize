Those scripts generate `KEYS_THAT_SHOULD_BE_REMOVED_WHEN_SHOP_IS_REPLACED` for StreetComplete project.

`make update` should be run periodically, to find new keys with usage > 0.01%
and add them to `## TODO ##` section at the bottom of `keys.txt` file.

User should then investigate and move them to correct section 
like `### KEYS TO REMOVE ###` or `### KEYS TO KEEP ###`

Script will then generate `sc_to_remove.txt` with kotlin code to copy/paste to 
https://github.com/streetcomplete/StreetComplete/blob/master/app/src/main/java/de/westnordost/streetcomplete/data/meta/OsmTaggings.kt
It is generated only from data in `### KEYS TO REMOVE ###` section.

Notes on `keys.txt` format:
* each line can contain a regex (or regular) text representing key (in-line
  comments are possible, as everything after `//` or `#` is ignored
* blank lines in `### KEYS TO REMOVE ###` section will become newlines in `sc_to_remove.txt`
* lines beginning with `//` in `### KEYS TO REMOVE ###` section will be copied to `sc_to_remove.txt`
* lines beginning with `#` are ignored completely
