BUILD = node_modules/.bin/skewc src --output-file=www/compiled.js

default: build-glslx build-fonts build-release

build-debug: | node_modules
	$(BUILD) --inline-functions

build-release: | node_modules
	$(BUILD) --release

build-fonts: | node_modules
	node fonts/generate.js

build-glslx: | node_modules
	node_modules/.bin/glslx glslx/shaders.glslx --output=src/core/shaders.sk --format=skew

watch-debug: | node_modules
	node_modules/.bin/watch src 'clear && make build-debug'

watch-release: | node_modules
	node_modules/.bin/watch src 'clear && make build-release'

watch-fonts: | node_modules
	node_modules/.bin/watch fonts 'clear && make build-fonts && echo done'

watch-glslx: | node_modules
	node_modules/.bin/watch glslx 'clear && make build-glslx && echo done'

node_modules:
	npm install

clean:
	rm -f src/core/shaders.sk www/compiled.js
