BUILD = node_modules/.bin/skewc src --output-file=www/compiled.js

default: build-glsl build-fonts build-release

build-debug: | node_modules
	$(BUILD) --inline-functions

build-release: | node_modules
	$(BUILD) --release

build-fonts: | node_modules
	node fonts/generate.js

build-glsl: | node_modules
	node_modules/.bin/glslx glsl/shaders.glsl --output=src/core/shaders.sk --format=skew

watch-debug: | node_modules
	node_modules/.bin/watch src 'clear && make build-debug'

watch-release: | node_modules
	node_modules/.bin/watch src 'clear && make build-release'

watch-fonts: | node_modules
	node_modules/.bin/watch fonts 'clear && make build-fonts && echo done'

watch-glsl: | node_modules
	node_modules/.bin/watch glsl 'clear && make build-glsl && echo done'

node_modules:
	npm install
