<!--
SPDX-FileCopyrightText: 2021,2025 Matija Nalis <mnalis-git@voyager.hr>

SPDX-License-Identifier: Apache-2.0
-->

- [x] also remove all main keys like "leisure, some office and one tourism"
  see https://github.com/streetcomplete/StreetComplete/pull/3278#discussion_r708695175
  but see what if we have cobined unrelated tags? shop=convenience + office=goverments in same building? can function remove tag it was invoked on automatically? or can we at least specify per-value removals to remove only office=insurance and not office=* ?

- [ ] script to detect and report duplicates in keys.txt (eg. note:* and note:en)? but there might in future be things we want that behaviour; like remove all "ref:*" except "ref:xxx". we currently can't handle that

- [X] fix unspecified licensing; see COPYING -- also use https://reuse.software/ ?
  need confirmation for:
    - 2024-09-22 23:12:34 +0200 waterced <waterced1@gmail.com> 37f54d6  added siren siret
    - 2021-09-06 09:54:57 +0200 smootheFiets <68379371+smootheFiets@users.noreply.github.com> 093d57e  Took care of most TODO's for shops.
  to add with e.g.:
    - reuse annotate --copyright "waterced <waterced1@gmail.com>" --license "CC0-1.0" --year 2024  --force-dot-license keys.txt

- [x] use REUSE.toml instead of *.txt.license files to consolidate authors in one place
  see https://reuse.software/faq/#bulk-license
