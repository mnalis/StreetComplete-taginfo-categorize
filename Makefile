# what keys/tags to fetch, and how
FETCH_KEYS := shop craft
FETCH_TAGS := information=office amenity=restaurant amenity=cafe amenity=ice_cream amenity=fast_food amenity=bar amenity=pub amenity=biergarten amenity=nightclub amenity=bank amenity=bureau_de_change amenity=money_transfer amenity=post_office amenity=internet_cafe amenity=pharmacy amenity=driving_school leisure=amusement_arcade leisure=adult_gaming_centre leisure=tanning_salon office=insurance office=travel_agent office=tax_advisor office=estate_agent office=political_party

MAX_TAGS := 501
CURL_URL_KEY := https://taginfo.openstreetmap.org/api/4/key/combinations?filter=all&sortname=to_count&sortorder=desc&page=1&rp=$(MAX_TAGS)&qtype=other_key&format=json_pretty
CURL_URL_TAG := https://taginfo.openstreetmap.org/api/4/tag/combinations?filter=all&sortname=to_count&sortorder=desc&page=1&rp=$(MAX_TAGS)&qtype=other_tag&format=json_pretty
CURL_FETCH = curl --silent --output $@

# those will be shop.json or amenity_cafe.json, respectively
FILES_KEYS := $(patsubst %,%.json,$(FETCH_KEYS))
FILES_TAGS := $(patsubst %,%.json,$(subst =,-,$(FETCH_TAGS)))


FULL_TAG = $(subst .json,,$@)
KEY_VALUE = $(subst -,&value=,$(FULL_TAG))

all: sc_to_remove.txt stats

sc_to_remove.txt: keys.txt Makefile generate_kotlin.pl
	./generate_kotlin.pl > $@

keys.txt: $(FILES_KEYS) $(FILES_TAGS) update_keys.pl
	[ `tail -c 1 keys.txt | od -A none -t d` -gt 32 ] && echo >> $@ || true

$(FILES_KEYS): Makefile
	@$(CURL_FETCH) '$(CURL_URL_KEY)&key=$(FULL_TAG)'
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

$(FILES_TAGS): Makefile
	@$(CURL_FETCH) '$(CURL_URL_TAG)&key=$(KEY_VALUE)'
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

stats:
	@echo "TO REMOVE: `sed -ne '1,/PROBABLY REMOVE/s/^\([a-z.]\)/\1/p' keys.txt  | wc -l`"
	@echo "TO KEEP  : `sed -ne '/KEEP/,/TODO/s/^\([a-z.]\)/\1/p' keys.txt  | wc -l`"
	@echo "TODO     : `sed -ne '/TODO/,$$s/^\([a-z.]\)/\1/p' keys.txt  | wc -l`"
	@[ `sed -ne '/TODO/,$$s/^\([a-z.]\)/\1/p' keys.txt  | wc -l` -eq 0 ]


clean:
	rm -f *.json *~

update: clean all

local_update:
	for j in *.json; do echo ./update_keys.pl $$j $(MAX_TAGS) >&2 ; ./update_keys.pl $$j $(MAX_TAGS); done >> keys.txt

.PHONY: clean update local_update stats all
