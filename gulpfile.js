"use strict";

var gulp = require("gulp");
var r = require("gulp-load-plugins")();

var extensionRegexp = /\.(css|js)$/;
var suffixRegexp = new RegExp("\\.(min|css$|js$)", "g");
var sourceMappingURLRegexp = /\n?\/(\/|\*)#\s*sourceMappingURL=.+(\*\/)?\w*$/;

var setSuffix = function(newSuffix) {
	return function(path) {
		// Maps add the extension to the basename so rewrite it at the end after adding the suffix.
		var ext = path.basename.match(extensionRegexp);
		path.basename = path.basename.replace(suffixRegexp, "") + newSuffix + (ext ? ext[0] : '');
	}
};

var src = {
	js: "src/*.coffee",
	css: "src/*.scss",
	lib: [
		"bower_components/angular/angular.js",
		"bower_components/jquery/dist/jquery.js",
		"bower_components/ng-annotate/dist/*latest.min*"
	],
	livereload: ["dist/*", "lib/*"]
};

var dest = {
	dist: "dist",
	lib: "lib"
};

gulp.task("default", function() {
	return gulp.start("js", "css", "lib");
});

gulp.task("watch", function() {
	gulp.watch(src.js, ["js"]);
	gulp.watch(src.css, ["css"]);
	gulp.watch(src.lib, ["lib"]);
	return gulp.start("default");
});

gulp.task("serve", function() {
	r.connect.server({
		port: 3000,
		root: ".",
		livereload: {
			ignore: [
				"^bower_components",
				"^node_modules"
			]
		}
	});
	return gulp.start("livereload", "watch");
});

gulp.task("livereload", function() {
	return gulp.src(src.livereload)
			.pipe(r.watch())
			.pipe(r.connect.reload());
});

gulp.task("js", function() {
	var stream = gulp.src(src.js)
			.pipe(r.sourcemaps.init())
			.pipe(r.coffee());

	// Full
	stream
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dist));

	// Minified
	stream
			// Mangle will shorten variable names which breaks the AngularJS dependency injection.
			// TODO: Use a build tool to preserve the important variables instead of disabling mangle.
			.pipe(r.uglify({mangle: false}))
			.pipe(r.rename(setSuffix(".min")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dist));

	return stream;
});

gulp.task("css", function() {
	var stream = gulp.src(src.css)
			.pipe(r.rubySass())
			.pipe(r.sourcemaps.init({loadMaps: true}))
			.pipe(r.autoprefixer("last 2 versions", "ie >= 9", "Firefox ESR"));

	// Full
	stream
			.pipe(r.sourcemaps.write('./'))
			.pipe(gulp.dest(dest.dist));

	// Minified
	stream
			// TODO: minifyCss breaks source maps
			.pipe(r.minifyCss())
			.pipe(r.rename(setSuffix(".min")))
			.pipe(r.replace(sourceMappingURLRegexp, ''))
			.pipe(r.sourcemaps.write("./"))
			.pipe(gulp.dest(dest.dist));

	return stream;
});

gulp.task("lib", function() {
	return gulp.src(src.lib)
			.pipe(gulp.dest(dest.lib));
});
