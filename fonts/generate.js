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

function compilePathCommands(commands) {
	var bytes = [];

	for (var i = 0; i < commands.length; i++) {
		var command = commands[i];
		switch (command.type) {
			case 'M': {
				bytes.push(Command.MOVE_TO);
				floatToBytes(command.x, bytes);
				floatToBytes(command.y, bytes);
				break;
			}

			case 'L': {
				bytes.push(Command.LINE_TO);
				floatToBytes(command.x, bytes);
				floatToBytes(command.y, bytes);
				break;
			}

			case 'Q': {
				bytes.push(Command.CURVE_TO);
				floatToBytes(command.x1, bytes);
				floatToBytes(command.y1, bytes);
				floatToBytes(command.x, bytes);
				floatToBytes(command.y, bytes);
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

	options.inputs.forEach(function(input) {
		var font = opentype.loadSync(input.path);
		ascender += font.ascender / font.unitsPerEm;
		descender += font.descender / font.unitsPerEm;
		for (var i = 0; i < input.chars.length; i++) {
			var char = input.chars[i];
			var glyph = font.charToGlyph(char);
			var path = glyph.getPath(0, 0, 1);
			var codePoint = char.charCodeAt(0);
			if (codePoint !== glyph.unicode) {
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
	var pathOffset = 12 + 16 * glyphs.length;

	floatToBytes(ascender / options.inputs.length, bytes);
	floatToBytes(descender / options.inputs.length, bytes);
	intToBytes(glyphs.length, bytes);

	for (var i = 0; i < glyphs.length; i++) {
		var glyph = glyphs[i];
		intToBytes(glyph.codePoint, bytes);
		floatToBytes(glyph.advanceWidth, bytes);
		intToBytes(pathOffset, bytes);
		intToBytes(glyph.path.length, bytes);
		pathOffset += glyph.path.length;
	}

	for (var i = 0; i < glyphs.length; i++) {
		var glyph = glyphs[i];
		bytes.push.apply(bytes, glyph.path);
	}

	var buffer = new Buffer(bytes);
	fs.writeFileSync(options.output, buffer);
}

function main() {
	process({
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
					'+−=<>≤≥,.',
					// ×·÷⁄√∫≠∏∑
			},
		],
		output: __dirname + '/../www/fonts.bin',
	});
}

main();
