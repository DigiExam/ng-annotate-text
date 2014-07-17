module.exports = (grunt) ->
	# Release
	distTasks = ["coffee:release", "sass:release", "autoprefixer:release", "uglify", "cssmin", "copy:release"]

	# Development
	defaultTasks = ["coffee:development", "sass:development", "autoprefixer:development"]
	watchTasks = defaultTasks

	grunt.initConfig
		pkg: grunt.file.readJSON "package.json"

		coffee:
			#options:
				#sourceMap: true
			release:
				src: ["js/src/ng-annotate.coffee"]
				dest: "dist/<%= pkg.version %>/js/<%= pkg.name %>-<%= pkg.version %>.js"

			development:
				src: ["js/src/ng-annotate.coffee"]
				dest: "dev/<%= pkg.name %>-unstable.js"

		sass:
			release:
				src: ["css/src/ng-annotate.scss"]
				dest: "dist/<%= pkg.version %>/css/<%= pkg.name %>-<%= pkg.version %>.css"

			development:
				src: ["css/src/ng-annotate.scss"]
				dest: "dev/<%= pkg.name %>-unstable.css"

		autoprefixer:
			options:
				browsers: [
					"last 2 versions"
					"ie >= 9"
					"Firefox ESR"
				]
			release:
				src: ["<%= sass.release.dest %>"]

			development:
				src: ["<%= sass.development.dest %>"]

		uglify:
			options:
				# Mangle will shorten variable names which breaks the AngularJS dependency injection.
				mangle: false
			release:
				src: "<%= coffee.release.dest %>"
				dest: "dist/<%= pkg.version %>/js/<%= pkg.name %>-<%= pkg.version %>.min.js"

		cssmin:
			release:
				src: "<%= sass.release.dest %>"
				dest: "dist/<%= pkg.version %>/css/<%= pkg.name %>-<%= pkg.version %>.min.css"

		copy:
			release:
				files: [
					{ src: "<%= uglify.release.dest %>", dest: "dist/ng-annotate-latest.min.js" }
					{ src: "<%= cssmin.release.dest %>", dest: "dist/ng-annotate-latest.min.css" }
				]

		watch:
			options:
				atBegin: true
			release:
				files: ["<%= coffee.release.src %>", "<%= sass.release.src %>"]
				tasks: watchTasks

	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-sass"
	grunt.loadNpmTasks "grunt-contrib-cssmin"
	grunt.loadNpmTasks "grunt-contrib-copy"
	grunt.loadNpmTasks "grunt-autoprefixer"

	grunt.registerTask "default", defaultTasks
	grunt.registerTask "dist", distTasks
