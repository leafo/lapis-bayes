
migrate: build
	make test_db > /dev/null
	lapis migrate

local: build
	luarocks --lua-version=5.1 make --local *-dev-1.rockspec

build:
	-rm $$(find lapis -type f | grep '\.lua$$')
	moonc lapis
	moonc *.moon

test_db:
	-dropdb -U postgres lapis_bayes
	createdb -U postgres lapis_bayes

lint::
	moonc lint_config.moon
	git ls-files | grep '\.moon$$' | grep -v config.moon | xargs -n 100 moonc -l

tags::
	moon-tags --lapis $$(git ls-files lapis/) > $@
