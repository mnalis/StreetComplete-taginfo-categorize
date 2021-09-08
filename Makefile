# what keys/tags to fetch, and how
FETCH_KEYS := shop craft
FETCH_TAGS := amenity=restaurant amenity=cafe
CURL_URL := https://taginfo.openstreetmap.org/api/4/key/combinations?filter=all&sortname=to_count&sortorder=desc&page=1&rp=801&qtype=other_key&format=json_pretty
CURL_FETCH = curl --silent --output $@

# those will be shop.json or amenity_cafe.json, respectively
FILES_KEYS := $(patsubst %,%.json,$(FETCH_KEYS))
FILES_TAGS := $(patsubst %,%.json,$(subst =,_,$(FETCH_TAGS)))

FULL_TAG = $(subst .json,,$@)
KEY_VALUE = $(subst _,&value=,$(FULL_TAG))

keys.txt: $(FILES_KEYS) $(FILES_TAGS) update_keys.pl

$(FILES_KEYS): Makefile
	@$(CURL_FETCH) '$(CURL_URL)&key=$(FULL_TAG)'
	./update_keys.pl $@ >> keys.txt

$(FILES_TAGS): Makefile
	@$(CURL_FETCH) '$(CURL_URL)&key=$(KEY_VALUE)'
	./update_keys.pl $@ >> keys.txt


clean:
	rm -f *.json *~

update: clean keys.txt

.PHONY: clean update
