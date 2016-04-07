# Theta

Website: http://thetamath.com

This is a simple web app that graphs an equation and allows you to pan and zoom around the coordinate grid. It was my winter 2015-2016 break project, developed here and there over two weeks. Interesting bits:

* Custom equation editor with exponents, fractions, and other stuff
* Live errors inline as you type, sort of like an IDE
* GPU-powered anti-aliased equation rendering, handles equations that are impossible to solve
* Custom text rendering using subpixel anti-aliasing and GPU quadratic curve evaluation (see the article [Easy Scalable Text Rendering on the GPU](https://medium.com/@evanwallace/c3f4d782c5ac) for a detailed description)
* Uses the [Skew](http://skew-lang.org/) programming language and the [GLSLX](http://evanw.github.io/glslx/) compiler, ends up as a [few dozen kilobytes](http://thetamath.com/compiled.js) of optimized JavaScript
* Abuses GitHub's custom 404 handler to make bookmarkable URLs without needing a hosting provider :)

Examples:

* http://thetamath.com/app/y=sin(3x+sin4(y+sin2(x+siny)))
* http://thetamath.com/app/sin(x-cosπy)≤sin(y+cosπx)
* http://thetamath.com/app/ysqrt(y^2+x^2)=x
* http://thetamath.com/app/sin(2lnr+θ)≤0
