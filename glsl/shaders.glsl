precision highp float;

uniform sampler2D texture;
uniform mat3 matrix3;
uniform vec4 color;

attribute vec2 position2;
attribute vec4 position4;
attribute vec4 coord4;

varying vec2 _coord2;
varying vec4 _coord4;

float gamma(float z) {
	float c[12];
	c[0] = 2.5066282746310002;
	c[1] = 198580.0627138776;
	c[2] = -696538.0071538021;
	c[3] = 984524.6972004089;
	c[4] = -719481.3805463574;
	c[5] = 290262.75410926086;
	c[6] = -64035.016015929315;
	c[7] = 7201.864420765037;
	c[8] = -354.97463894564885;
	c[9] = 5.661005637674728;
	c[10] = -0.014743849521331018;
	c[11] = 7.490856008760596e-7;
	float value = c[0];
	for (int k = 1; k < 12; k++) {
		value += c[k] / (z + float(k));
	}
	return -value * exp(-z - 12.0) * pow(z + 12.0, z + 0.5) / z;
}

////////////////////////////////////////////////////////////////////////////////

export void smoothVertex() {
	_coord2 = position4.zw;
	_coord4 = coord4;
	gl_Position = vec4(matrix3 * vec3(position4.xy, 1.0), 0.0).xywz;
}

export void smoothFragment() {
	gl_FragColor = _coord4 * min(1.0, min(_coord2.x, _coord2.y));
}

////////////////////////////////////////////////////////////////////////////////

export void glyphVertex() {
	_coord2 = position4.zw;
	gl_Position = vec4(matrix3 * vec3(position4.xy, 1.0), 0.0).xywz;
}

export void glyphFragment() {
	if (_coord2.x * _coord2.x - _coord2.y > 0.0) {
		discard;
	}

	// Upper 4 bits: front faces
	// Lower 4 bits: back faces
	gl_FragColor = color * (gl_FrontFacing ? 16.0 / 255.0 : 1.0 / 255.0);
}

////////////////////////////////////////////////////////////////////////////////

export void textVertex() {
	_coord2 = position2 * 0.5 + 0.5;
	gl_Position = vec4(position2, 0.0, 1.0);
}

export void textFragment() {
	// Get samples for -2/3 and -1/3
	vec2 valueL = texture2D(texture, vec2(_coord2.x + dFdx(_coord2.x), _coord2.y)).yz * 255.0;
	vec2 lowerL = mod(valueL, 16.0);
	vec2 upperL = (valueL - lowerL) / 16.0;
	vec2 alphaL = min(abs(upperL - lowerL), 2.0);

	// Get samples for 0, +1/3, and +2/3
	vec3 valueR = texture2D(texture, _coord2).xyz * 255.0;
	vec3 lowerR = mod(valueR, 16.0);
	vec3 upperR = (valueR - lowerR) / 16.0;
	vec3 alphaR = min(abs(upperR - lowerR), 2.0);

	// Average the energy over the pixels on either side
	gl_FragColor = vec4(1.0 - vec3(
		alphaR.x + alphaR.y + alphaR.z,
		alphaL.y + alphaR.x + alphaR.y,
		alphaL.x + alphaL.y + alphaR.x
	) / 6.0, 1.0);
}
