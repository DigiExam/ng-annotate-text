"use strict";

var gulp = require("gulp");
var r = require("gulp-load-plugins")();

var bowerJson = require("./bower.json");
var escapedVersion = bowerJson.version.replace(/\./g, "\\.");

var extensionRegexp = /\.(css|js)$/;
var suffixRegexp = new RegExp("(-(unstable|latest|" + escapedVersion + "))|\\.(min|css$|js$)", "g");
var sourceMappingURLRegexp = /\n?\/(\/|\*)#\s*sourceMappingURL=.+(\*\/)?\w*$/;

var setSuffix = function(newSuffix) {
	return function(path) {
		// Maps add the extension to the basename so rewrite it at the end after adding the suffix.
		var ext = path.basename.match(extensionRegexp);
		path.basename = path.basename.replace(suffixRegexp, "") + newSuffix + (ext ? ext[0] : '');
	}
};

var src = {
	js: "js/src/*.coffee",
	css: "css/src/*.scss"
};

var dest = {
	dev: "dev",
	dist: {
		version: {
			js: "dist/" + bowerJson.version + "/js",
			css: "dist/" + bowerJson.version + "/css"
		},
		latest: "dist"
	}
};

gulp.task("default", function() {
	return gulp.start("js", "css");
});

gulp.task("watch", function() {
	gulp.watch(src.js, ["js"]);
	gulp.watch(src.css, ["css"]);
	return gulp.start("default");
});

gulp.task("js", function() {
	var stream = gulp.src(src.js)
			.pipe(r.sourcemaps.init())
			.pipe(r.coffee());

	// Full
	stream
			// Dist version
			.pipe(r.rename(setSuffix("-" + bowerJson.version)))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dist.version.js))
			// Dev unstable
			.pipe(r.rename(setSuffix("-unstable")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dev))
			// Dist latest
			.pipe(r.rename(setSuffix("-latest")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dist.latest));

	// Minified
	stream
			// Mangle will shorten variable names which breaks the AngularJS dependency injection.
			// TODO: Use a build tool to preserve the important variables instead of disabling mangle.
			.pipe(r.uglify({mangle: false}))
			// Dist version
			.pipe(r.rename(setSuffix("-" + bowerJson.version + ".min")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dist.version.js))
			// Dev unstable
			.pipe(r.rename(setSuffix("-unstable.min")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dev))
			// Dist latest
			.pipe(r.rename(setSuffix("-latest.min")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dist.latest));

	return stream;
});

gulp.task("css", function() {
	var stream = gulp.src(src.css)
			.pipe(r.rubySass())
			.pipe(r.sourcemaps.init({loadMaps: true}))
			.pipe(r.autoprefixer("last 2 versions", "ie >= 9", "Firefox ESR"));

	// Full
	stream
			// Dist version
			.pipe(r.rename(setSuffix("-" + bowerJson.version)))
			.pipe(r.sourcemaps.write('./'))
			.pipe(gulp.dest(dest.dist.version.css))
			// Dev unstable
			.pipe(r.rename(setSuffix("-unstable")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write('./'))
			.pipe(gulp.dest(dest.dev))
			// Dist latest
			.pipe(r.rename(setSuffix("-latest")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write('./'))
			.pipe(gulp.dest(dest.dist.latest));

	// Minified
	stream
			// TODO: minifyCss breaks source maps
			.pipe(r.minifyCss())
			// Dist version
			.pipe(r.rename(setSuffix("-" + bowerJson.version + ".min")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dist.version.css))
			// Dev unstable
			.pipe(r.rename(setSuffix("-unstable.min")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dev))
			// Dist latest
			.pipe(r.rename(setSuffix("-latest.min")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dist.latest));

	return stream;
});
