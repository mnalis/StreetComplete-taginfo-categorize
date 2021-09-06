keys.txt: shop.json craft.json update_keys.pl
	./update_keys.pl shop.json >> $@
	./update_keys.pl craft.json >> $@

shop.json: Makefile
	curl -s 'https://taginfo.openstreetmap.org/api/4/key/combinations?key=shop&filter=all&sortname=to_count&sortorder=desc&page=1&rp=801&qtype=other_key&format=json_pretty' > $@

craft.json: Makefile
	curl -s 'https://taginfo.openstreetmap.org/api/4/key/combinations?key=craft&filter=all&sortname=to_count&sortorder=desc&page=1&rp=601&qtype=other_key&format=json_pretty' > $@
