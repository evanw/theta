precision highp float;

uniform mat3 matrix3;
uniform vec4 value4;

attribute vec2 position2;
attribute vec4 position4;
attribute vec4 coord4;

varying vec2 _coord2;
varying vec4 _coord4;

export void smoothPathVertex() {
	_coord2 = position4.zw;
	_coord4 = coord4;
	gl_Position = vec4(matrix3 * vec3(position4.xy, 1.0), 0.0).xywz;
}

export void smoothPathFragment() {
	gl_FragColor = _coord4 * min(1.0, min(_coord2.x, _coord2.y));
}

export void demoVertex() {
	gl_Position = vec4(position2, 0.0, 1.0);
}

export void demoFragment() {
	vec2 pixel = gl_FragCoord.xy;
	float x = (pixel.x - value4.x) / value4.z;
	float y = (value4.w - pixel.y - value4.y) / value4.z;

	// float z = cos(x - sin(y)) - cos(y + sin(x));
	float z = 0.0;
	for (int i = 1; i < 10; i++)
		z +=
			cos(x * 4.0 / float(i)) +
			sin(y * 4.0 / float(i)) +
			sin(sqrt(x * x + y * y) * 4.0 / float(i));

	float edge = clamp(1.0 - abs(z) / fwidth(z), 0.0, 1.0);
	float area = clamp(0.5 + z / fwidth(z), 0.0, 1.0);
	float alpha = mix(edge, 1.0, area * 0.25);
	gl_FragColor = vec4(0.0, 0.5, 1.0, 1.0) * alpha;
}
