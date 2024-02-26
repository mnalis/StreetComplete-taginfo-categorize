# what keys/tags to fetch, and how
# content of FETCH_KEYS.make & FETCH_TAGS.make should match https://github.com/streetcomplete/StreetComplete/blob/master/app/src/main/java/de/westnordost/streetcomplete/osm/Place.kt
FETCH_KEYS := $(shell cat FETCH_KEYS.make)
FETCH_TAGS := $(shell cat FETCH_TAGS.make)

# paths to id-tagging-schema and StreetComplete git working directories
ID_DATA_PATH=../id-tagging-schema/data/presets
STREETCOMPLETE_PATH=../StreetComplete

MAX_TAGS := 999
CURL_URL_TAG  := https://taginfo.openstreetmap.org/api/4/tag/combinations?filter=all&sortname=to_count&sortorder=desc&page=1&rp=$(MAX_TAGS)&qtype=other_tag&format=json_pretty
CURL_URL_KEY  := https://taginfo.openstreetmap.org/api/4/key/combinations?filter=all&sortname=to_count&sortorder=desc&page=1&rp=$(MAX_TAGS)&qtype=other_key&format=json_pretty
CURL_URL_KEY2 := https://taginfo.openstreetmap.org/api/4/key/values?filter=all&lang=en&sortname=count&sortorder=desc&page=1&rp=$(MAX_TAGS)&qtype=value&format=json_pretty
CURL_FETCH = curl --silent --output $@

# those will be e.g. shop.json or amenity_cafe.json, respectively
FILES_KEYS := $(patsubst %,%.json,$(FETCH_KEYS))
FILES_TAGS := $(patsubst %,%.json,$(subst =,-,$(FETCH_TAGS)))

FULL_TAG = $(subst .json,,$@)
KEY_VALUE = $(subst -,&value=,$(FULL_TAG))

FILES_KEYS2 := $(patsubst %,%.json2,$(FETCH_KEYS))
FULL_TAG2 = $(subst .json2,,$@)
KEY_VALUE2 = $(subst -,&value=,$(FULL_TAG2))

define txt-to-json
	perl -MJSON -nE 'next if /^#|^\s*$$/; s/\s*#.*$$//; chomp;$$KEYS{$$_}=1; END {my @data = map {other_key=> $$_, other_value=>"", to_fraction=>1, from_fraction=>1, together_count=>999}, keys %KEYS; say encode_json {"page"=>1, "data" => \@data };}' $< | json_reformat > $@
endef


all: sc_to_remove.txt sc_to_keep.txt stats

test:
	@echo "Fetch keys is: $(FETCH_TAGS)"

sc_to_remove.txt: keys.txt Makefile generate_kotlin.pl
	./generate_kotlin.pl '### KEYS TO REMOVE ###' '### KEYS TO KEEP ###' 'KEYS_THAT_SHOULD_BE_REMOVED_WHEN_PLACE_IS_REPLACED' > $@

sc_to_keep.txt: keys.txt Makefile generate_kotlin.pl
	./generate_kotlin.pl '### KEYS TO KEEP ###' '### TODO' 'KEYS_THAT_SHOULD_NOT_BE_REMOVED_WHEN_PLACE_IS_REPLACED' > $@

keys.txt: _find_popular_subkeys.json $(FILES_KEYS) $(FILES_TAGS) update_keys.pl _id_tagging_schema.json
	@[ `tail -c 1 keys.txt | od -A none -t d` -gt 32 ] && echo >> $@ || true
	[ -z "`sort keys.txt | sed -e 's,\s*//.*$$,,g' | cat -s | uniq -dc`" ]

$(FILES_KEYS): FETCH_KEYS.make
	@$(CURL_FETCH) '$(CURL_URL_KEY)&key=$(FULL_TAG)'
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

$(FILES_TAGS): FETCH_TAGS.make
	@$(CURL_FETCH) '$(CURL_URL_TAG)&key=$(KEY_VALUE)'
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

stats:
	@echo "TO REMOVE: `sed -ne '1,/PROBABLY REMOVE/s/^\([a-z.]\)/\1/p' keys.txt  | wc -l`"
	@echo "TO KEEP  : `sed -ne '/KEEP/,/TODO/s/^\([a-z.]\)/\1/p' keys.txt  | wc -l`"
	@echo "TODO     : `sed -ne '/TODO/,$$s/^\([a-z.]\)/\1/p' keys.txt  | wc -l` more need categorising at the end in keys.txt file"
	@[ `sed -ne '/TODO/,$$s/^\([a-z.]\)/\1/p' keys.txt  | wc -l` -eq 0 ]

$(FILES_KEYS2): FETCH_KEYS.make
	$(CURL_FETCH) '$(CURL_URL_KEY2)&key=$(KEY_VALUE2)'

_find_popular_subkeys.txt: $(FILES_KEYS2) find_popular_subkeys.pl FETCH_KEYS.make
	./find_popular_subkeys.pl $(FILES_KEYS2) > $@.tmp && mv -f $@.tmp $@

_find_popular_subkeys.json: _find_popular_subkeys.txt
	$(txt-to-json)
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

clean:
	rm -f *.json *.json2 *~ _id_tagging_schema.txt _find_popular_subkeys.txt *.tmp

distclean: clean
	rm -f sc_to_keep.txt sc_to_remove.txt

update_id:
	cd $(ID_DATA_PATH) && git pull

update_sc:
	cd $(STREETCOMPLETE_PATH) && git pull

update: clean update_id update_sc all

local_update:
	for j in *.json; do echo ./update_keys.pl $$j $(MAX_TAGS) >&2 ; ./update_keys.pl $$j $(MAX_TAGS); done >> keys.txt

# FIXME hardcoded keys dependencies !
_id_tagging_schema.txt: parse_id_tagging_schema.pl $(ID_DATA_PATH)/shop/*.json $(ID_DATA_PATH)/craft/*.json $(ID_DATA_PATH)/amenity/*.json $(ID_DATA_PATH)/leisure/*.json $(ID_DATA_PATH)/office/*.json
	for k in $(FETCH_KEYS); do ./parse_id_tagging_schema.pl $(ID_DATA_PATH)/$$k.json; for t in $(ID_DATA_PATH)/$$k/*.json; do ./parse_id_tagging_schema.pl $$t; done; done > $@
	for t in $(subst =,/,$(FETCH_TAGS)); do find $(ID_DATA_PATH) -iwholename "*/$$t.json" -print0 | xargs -0ri ./parse_id_tagging_schema.pl {}; done >> $@

_id_tagging_schema.json: _id_tagging_schema.txt
	$(txt-to-json)
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

.PHONY: clean distclean update update_id update_sc local_update stats all
