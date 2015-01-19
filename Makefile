
.PHONY: clean_test test

clean_test:
	-dropdb -U postgres community_test
	createdb -U postgres community_test
	LAPIS_SHOW_QUERIES=1 LAPIS_ENVIRONMENT=test lua5.1 -e 'require("schema").make_schema()'
	LAPIS_SHOW_QUERIES=1 LAPIS_ENVIRONMENT=test lua5.1 -e 'require("community.schema").make_schema()'

test:
	busted

lint:
	moonc -l community/
	moonc -l spec/
