# what keys/tags to fetch, and how
# this should match https://github.com/streetcomplete/StreetComplete/blob/master/app/src/main/java/de/westnordost/streetcomplete/osm/Place.kt
FETCH_KEYS := craft healthcare office shop
FETCH_TAGS := information=office information=visitor_centre \
amenity=bar amenity=biergarten amenity=cafe amenity=fast_food amenity=food_court amenity=ice_cream amenity=pub amenity=restaurant \
amenity=childcare amenity=college amenity=dancing_school amenity=dive_centre amenity=dojo amenity=driving_school amenity=kindergarten \
amenity=language_school amenity=library amenity=music_school amenity=prep_school amenity=research_institute amenity=school \
amenity=toy_library amenity=training amenity=university amenity=boat_rental amenity=car_rental amenity=car_wash amenity=fuel \
amenity=motorcycle_rental amenity=vehicle_inspection amenity=bank amenity=bureau_de_change amenity=mobile_money_agent \
amenity=money_transfer amenity=payment_centre \
amenity=clinic amenity=dentist amenity=doctors amenity=health_post amenity=hospital amenity=nursing_home amenity=pharmacy \
amenity=social_facility amenity=veterinary amenity=archive amenity=arts_centre amenity=brothel amenity=casino amenity=cinema \
amenity=community_centre amenity=conference_centre amenity=events_venue amenity=exhibition_centre amenity=gambling \
amenity=hookah_lounge amenity=love_hotel amenity=music_venue amenity=nightclub amenity=planetarium amenity=ski_rental \
amenity=social_centre amenity=stripclub amenity=studio amenity=swingerclub amenity=theatre amenity=courthouse amenity=embassy \
amenity=fire_station amenity=mailroom amenity=police amenity=post_depot amenity=post_office amenity=prison amenity=ranger_station \
amenity=townhall amenity=lavoir amenity=left_luggage amenity=animal_boarding amenity=animal_shelter amenity=animal_training \
amenity=coworking_space amenity=crematorium amenity=funeral_hall amenity=internet_cafe amenity=meditation_centre amenity=monastery \
amenity=mortuary amenity=place_of_mourning amenity=place_of_worship amenity=public_bath \
emergency=air_rescue_service emergency=ambulance_station emergency=disaster_response emergency=mountain_rescue emergency=water_rescue \
leisure=adult_gaming_centre leisure=amusement_arcade leisure=bowling_alley leisure=dance leisure=escape_game leisure=fitness_centre \
leisure=hackerspace leisure=ice_rink leisure=indoor_play leisure=sauna leisure=sports_hall leisure=stadium leisure=tanning_salon leisure=trampoline_park \
military=office \
tourism=alpine_hut tourism=apartment tourism=aquarium tourism=chalet tourism=gallery tourism=guest_house tourism=hostel tourism=hotel \
tourism=hunting_lodge tourism=museum tourism=motel tourism=trail_riding_station tourism=wilderness_hut

ID_DATA_PATH=../id-tagging-schema/data/presets

MAX_TAGS := 999
CURL_URL_TAG  := https://taginfo.openstreetmap.org/api/4/tag/combinations?filter=all&sortname=to_count&sortorder=desc&page=1&rp=$(MAX_TAGS)&qtype=other_tag&format=json_pretty
CURL_URL_KEY  := https://taginfo.openstreetmap.org/api/4/key/combinations?filter=all&sortname=to_count&sortorder=desc&page=1&rp=$(MAX_TAGS)&qtype=other_key&format=json_pretty
CURL_URL_KEY2 := https://taginfo.openstreetmap.org/api/4/key/values?filter=all&lang=en&sortname=count&sortorder=desc&page=1&rp=$(MAX_TAGS)&qtype=value&format=json_pretty
CURL_FETCH = curl --silent --output $@

# those will be shop.json or amenity_cafe.json, respectively
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

sc_to_remove.txt: keys.txt Makefile generate_kotlin.pl
	./generate_kotlin.pl '### KEYS TO REMOVE ###' '### KEYS TO KEEP ###' 'KEYS_THAT_SHOULD_BE_REMOVED_WHEN_PLACE_IS_REPLACED' > $@

sc_to_keep.txt: keys.txt Makefile generate_kotlin.pl
	./generate_kotlin.pl '### KEYS TO KEEP ###' '### TODO' 'KEYS_THAT_SHOULD_NOT_BE_REMOVED_WHEN_PLACE_IS_REPLACED' > $@

keys.txt: _find_popular_subkeys.json $(FILES_KEYS) $(FILES_TAGS) update_keys.pl _id_tagging_schema.json
	@[ `tail -c 1 keys.txt | od -A none -t d` -gt 32 ] && echo >> $@ || true
	[ -z "`sort keys.txt | cat -s | uniq -dc`" ]

$(FILES_KEYS): Makefile
	@$(CURL_FETCH) '$(CURL_URL_KEY)&key=$(FULL_TAG)'
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

$(FILES_TAGS): Makefile
	@$(CURL_FETCH) '$(CURL_URL_TAG)&key=$(KEY_VALUE)'
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

stats:
	@echo "TO REMOVE: `sed -ne '1,/PROBABLY REMOVE/s/^\([a-z.]\)/\1/p' keys.txt  | wc -l`"
	@echo "TO KEEP  : `sed -ne '/KEEP/,/TODO/s/^\([a-z.]\)/\1/p' keys.txt  | wc -l`"
	@echo "TODO     : `sed -ne '/TODO/,$$s/^\([a-z.]\)/\1/p' keys.txt  | wc -l` more need categorising at the end in keys.txt file"
	@[ `sed -ne '/TODO/,$$s/^\([a-z.]\)/\1/p' keys.txt  | wc -l` -eq 0 ]

$(FILES_KEYS2): Makefile
	$(CURL_FETCH) '$(CURL_URL_KEY2)&key=$(KEY_VALUE2)'

_find_popular_subkeys.txt: $(FILES_KEYS2) find_popular_subkeys.pl Makefile
	./find_popular_subkeys.pl $(FILES_KEYS2) > $@

_find_popular_subkeys.json: _find_popular_subkeys.txt Makefile
	$(txt-to-json)
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

clean:
	rm -f *.json *.json2 *~ _id_tagging_schema.txt _find_popular_subkeys.txt

distclean: clean
	rm -f sc_to_keep.txt sc_to_remove.txt

update_id:
	cd $(ID_DATA_PATH) && git pull

update: clean update_id all

local_update:
	for j in *.json; do echo ./update_keys.pl $$j $(MAX_TAGS) >&2 ; ./update_keys.pl $$j $(MAX_TAGS); done >> keys.txt

_id_tagging_schema.txt: parse_id_tagging_schema.pl $(ID_DATA_PATH)/shop/*.json $(ID_DATA_PATH)/craft/*.json $(ID_DATA_PATH)/amenity/*.json $(ID_DATA_PATH)/leisure/*.json $(ID_DATA_PATH)/office/*.json
	for k in $(FETCH_KEYS); do ./parse_id_tagging_schema.pl $(ID_DATA_PATH)/$$k.json; for t in $(ID_DATA_PATH)/$$k/*.json; do ./parse_id_tagging_schema.pl $$t; done; done > $@
	for t in $(subst =,/,$(FETCH_TAGS)); do find $(ID_DATA_PATH) -iwholename "*/$$t.json" -print0 | xargs -0ri ./parse_id_tagging_schema.pl {}; done >> $@

_id_tagging_schema.json: _id_tagging_schema.txt Makefile
	$(txt-to-json)
	./update_keys.pl $@ $(MAX_TAGS) >> keys.txt

.PHONY: clean distclean update update_id local_update stats all
