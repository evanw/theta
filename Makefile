BUILD = node_modules/.bin/skewc src --output-file=www/compiled.js
SHADERS = src/core/shaders.sk

debug: | node_modules
	$(BUILD) --inline-functions

release: | node_modules
	$(BUILD) --release

$(SHADERS): shaders

shaders: | node_modules
	node_modules/.bin/glslx glsl/*.glsl --output=$(SHADERS) --format=skew

watch-debug: | node_modules
	node_modules/.bin/watch src 'clear && make debug'

watch-release: | node_modules
	node_modules/.bin/watch src 'clear && make release'

watch-shaders: | node_modules
	node_modules/.bin/watch glsl 'clear && make shaders && echo done'

node_modules:
	npm install
