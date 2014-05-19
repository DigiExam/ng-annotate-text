module.exports = (grunt) ->
	distTasks = ["coffee", "uglify"]
	defaultTasks = ["coffee"]
	watchTasks = ["coffee"]

	grunt.initConfig
		pkg: grunt.file.readJSON "package.json"

		coffee:
			release: 
				src: ["js/src/ng-annotate.coffee"]
				dest: "dist/<%= pkg.version %>/<%= pkg.name %>-<%= pkg.version %>.js"

		uglify:
			options:
				mangle: true
			release:
				src: "<%= coffee.release.dest %>"
				dest: "dist/<%= pkg.version %>/<%= pkg.name %>-<%= pkg.version %>.min.js"

		watch:
			release:
				files: ["<%= coffee.release.src %>"]
				tasks: watchTasks
	
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-watch"
	
	grunt.registerTask "default", defaultTasks
	grunt.registerTask "dist", distTasks