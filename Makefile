# what keys/tags to fetch, and how
FETCH_KEYS := shop craft
FETCH_TAGS := information=office amenity=restaurant amenity=cafe amenity=ice_cream amenity=fast_food amenity=bar amenity=pub amenity=biergarten amenity=nightclub amenity=bank amenity=bureau_de_change amenity=money_transfer amenity=post_office amenity=internet_cafe amenity=pharmacy amenity=driving_school leisure=amusement_arcade leisure=adult_gaming_centre leisure=tanning_salon office=insurance office=travel_agent office=tax_advisor office=estate_agent office=political_party

CURL_URL_KEY := https://taginfo.openstreetmap.org/api/4/key/combinations?filter=all&sortname=to_count&sortorder=desc&page=1&rp=801&qtype=other_key&format=json_pretty
CURL_URL_TAG := https://taginfo.openstreetmap.org/api/4/tag/combinations?filter=all&sortname=to_count&sortorder=desc&page=1&rp=801&qtype=other_tag&format=json_pretty
CURL_FETCH = curl --silent --output $@

# those will be shop.json or amenity_cafe.json, respectively
FILES_KEYS := $(patsubst %,%.json,$(FETCH_KEYS))
FILES_TAGS := $(patsubst %,%.json,$(FETCH_TAGS))

FULL_TAG = $(subst .json,,$@)
KEY_VALUE = $(subst =,&value=,$(FULL_TAG))

keys.txt: $(FILES_KEYS) $(FILES_TAGS) update_keys.pl

$(FILES_KEYS): Makefile
	$(CURL_FETCH) '$(CURL_URL_KEY)&key=$(FULL_TAG)'
	./update_keys.pl $@ >> keys.txt

$(FILES_TAGS): Makefile
	$(CURL_FETCH) '$(CURL_URL_TAG)&key=$(KEY_VALUE)'
	./update_keys.pl $@ >> keys.txt

stats:
	@echo "TO REMOVE: `sed -ne '1,/PROBABLY REMOVE/s/^\([a-z]\)/\1/p' keys.txt  | wc -l`"
	@echo "TO KEEP  : `sed -ne '/KEEP/,/TODO/s/^\([a-z]\)/\1/p' keys.txt  | wc -l`"


clean:
	rm -f *.json *~

update: clean keys.txt

.PHONY: clean update stats
