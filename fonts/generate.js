var opentype = require('opentype.js');
var fs = require('fs');

var byteArray = new Uint8Array(4);
var floatArray = new Float32Array(byteArray.buffer);
var shortArray = new Int16Array(byteArray.buffer);
var intArray = new Int32Array(byteArray.buffer);

var Command = {
	MOVE_TO: 0,
	LINE_TO: 1,
	CURVE_TO: 2,
	CLOSE: 3,
};

function floatToBytes(float, bytes) {
	floatArray[0] = float;
	bytes.push(
		byteArray[0],
		byteArray[1],
		byteArray[2],
		byteArray[3]);
}

function shortToBytes(short, bytes) {
	if (short < -0x8000 || short > 0x7FFF) {
		throw new Error('Cannot store ' + short + ' as a short');
	}
	shortArray[0] = short;
	bytes.push(
		byteArray[0],
		byteArray[1]);
}

function intToBytes(int, bytes) {
	intArray[0] = int;
	bytes.push(
		byteArray[0],
		byteArray[1],
		byteArray[2],
		byteArray[3]);
}

function compilePathCommands(commands, units) {
	var bytes = [];

	for (var i = 0; i < commands.length; i++) {
		var command = commands[i];
		switch (command.type) {
			case 'M': {
				bytes.push(Command.MOVE_TO);
				shortToBytes(Math.round(command.x * units), bytes);
				shortToBytes(Math.round(command.y * units), bytes);
				break;
			}

			case 'L': {
				bytes.push(Command.LINE_TO);
				shortToBytes(Math.round(command.x * units), bytes);
				shortToBytes(Math.round(command.y * units), bytes);
				break;
			}

			case 'Q': {
				bytes.push(Command.CURVE_TO);
				shortToBytes(Math.round(command.x1 * units), bytes);
				shortToBytes(Math.round(command.y1 * units), bytes);
				shortToBytes(Math.round(command.x * units), bytes);
				shortToBytes(Math.round(command.y * units), bytes);
				break;
			}

			case 'Z': {
				bytes.push(Command.CLOSE);
				break;
			}

			default: {
				throw new Error('Unsupported command "' + command.type + '"');
			}
		}
	}

	return bytes;
}

function process(options) {
	var glyphs = [];
	var ascender = 0;
	var descender = 0;
	var units = options.unitsPerEm;

	options.inputs.forEach(function(input) {
		var font = opentype.loadSync(input.path);
		ascender += font.ascender / font.unitsPerEm * units;
		descender += font.descender / font.unitsPerEm * units;
		for (var i = 0; i < input.chars.length; i++) {
			var char = input.chars[i];
			var glyph = font.charToGlyph(char);
			var path = glyph.getPath(0, 0, 1);
			var codePoint = char.charCodeAt(0);
			if (codePoint !== glyph.unicode && glyph.unicode !== void 0) {
				throw new Error('Font "' + input.path + '" is missing character "' + char + '"');
			}
			glyphs.push({
				codePoint: codePoint,
				advanceWidth: glyph.advanceWidth / font.unitsPerEm,
				path: compilePathCommands(path.commands, font.unitsPerEm),
			});
		}
	});

	var bytes = [];
	var pathOffset = 8 + 10 * glyphs.length;

	ascender = Math.round(ascender / options.inputs.length);
	descender = Math.round(descender / options.inputs.length);

	shortToBytes(units, bytes);
	shortToBytes(ascender, bytes);
	shortToBytes(descender, bytes);
	shortToBytes(glyphs.length, bytes);

	for (var i = 0; i < glyphs.length; i++) {
		var glyph = glyphs[i];
		shortToBytes(glyph.codePoint, bytes);
		shortToBytes(Math.round(glyph.advanceWidth * units), bytes);
		intToBytes(pathOffset, bytes);
		shortToBytes(glyph.path.length, bytes);
		pathOffset += glyph.path.length;
	}

	for (var i = 0; i < glyphs.length; i++) {
		bytes.push.apply(bytes, glyphs[i].path);
	}

	var buffer = new Buffer(bytes);
	fs.writeFileSync(options.output, buffer);
}

function main() {
	process({
		unitsPerEm: 1000,
		inputs: [
			{
				path: __dirname + '/FreeSerifItalic.ttf',
				chars:
					'abcdefghijklmnopqrstuvwxyz' +
					'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
					'αβγδεζηθικλμνξοπρστυφχψω',
			},
			{
				path: __dirname + '/FreeSerif.ttf',
				chars:
					'ΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩ' +
					'0123456789' +
					'+−·÷=<>≤≥,.! \0',
					// ⁄×√∫≠∏∑
			},
		],
		output: __dirname + '/../www/fonts.bin',
	});
}

main();
