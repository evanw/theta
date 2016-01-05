precision highp float;

uniform sampler2D texture;
uniform float thicknessAndMode;
uniform mat3 matrix3;
uniform vec4 color;
uniform vec4 rect;

attribute vec2 position2;
attribute vec4 position4;
attribute vec4 coord4;

varying vec2 _coord2;
varying vec4 _coord4;

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
	_coord2 = mix(rect.xy, rect.zw, position2 * 0.5 + 0.5);
	gl_Position = vec4(_coord2 * 2.0 - 1.0, 0.0, 1.0);
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
	vec4 rgba = vec4(
		(alphaR.x + alphaR.y + alphaR.z) / 6.0,
		(alphaL.y + alphaR.x + alphaR.y) / 6.0,
		(alphaL.x + alphaL.y + alphaR.x) / 6.0,
		0.0);

	// Optionally scale by a color
	gl_FragColor = color.a == 0.0 ? 1.0 - rgba : color * rgba;
}

////////////////////////////////////////////////////////////////////////////////

import float eq(float x, float y);

export void equationVertex() {
	_coord2 = (matrix3 * vec3(position2, 1.0)).xy;
	gl_Position = vec4(position2, 0.0, 1.0);
}

export void equationFragment() {
	float x = _coord2.x;
	float y = _coord2.y;
	float dx = dFdx(x);
	float dy = dFdy(y);
	float z = eq(x,y);

	// Evaluate all 4 adjacent +/- neighbor pixels
	vec2 z_neg = vec2(eq(x - dx, y), eq(x, y - dy));
	vec2 z_pos = vec2(eq(x + dx, y), eq(x, y + dy));

	// Compute the x and y slopes
	vec2 slope = (z_pos-z_neg) * 0.5;

	// Compute the gradient (the shortest point on the curve is assumed to lie in this direction)
	vec2 gradient = normalize(slope);

	// Use the parabola "a*t^2 + b*t + z = 0" to approximate the function along the gradient
	float a = dot((z_neg + z_pos) * 0.5 - z, gradient * gradient);
	float b = dot(slope, gradient);

	// The distance to the curve is the closest solution to the parabolic equation
	float distanceToCurve = 0.0;
	float thickness = abs(thicknessAndMode);

	// Linear equation: "b*t + z = 0"
	if (abs(a) < 1.0e-6) {
		distanceToCurve = abs(z / b);
	}

	// Quadratic equation: "a*t^2 + b*t + z = 0"
	else {
		float discriminant = b * b - 4.0 * a * z;
		if (discriminant < 0.0) {
			distanceToCurve = thickness;
		} else {
			discriminant = sqrt(discriminant);
			distanceToCurve = min(abs(b + discriminant), abs(b - discriminant)) / abs(2.0 * a);
		}
	}

	// Antialias the edge using the distance from the curve
	float edgeAlpha = clamp(abs(thickness) - distanceToCurve, 0.0, 1.0);

	// Combine edge and area for color
	gl_FragColor = color * (
		thicknessAndMode == 0.0 ? clamp(0.5 + z / b, 0.0, 1.0) * 0.25 :
		thicknessAndMode < 0.0 ? mix(edgeAlpha, 1.0, z > 0.0 ? 0.25 : 0.0) :
		edgeAlpha);
}
