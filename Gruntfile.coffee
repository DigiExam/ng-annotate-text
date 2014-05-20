module.exports = (grunt) ->
	distTasks = ["coffee", "sass", "uglify", "cssmin"]
	defaultTasks = ["coffee", "sass"]
	watchTasks = ["coffee", "sass"]

	grunt.initConfig
		pkg: grunt.file.readJSON "package.json"

		coffee:
			options:
				sourceMap: true
			release: 
				src: ["js/src/ng-annotate.coffee"]
				dest: "dist/<%= pkg.version %>/js/<%= pkg.name %>-<%= pkg.version %>.js"

		sass:
			release:
				src: ["css/src/ng-annotate.scss"]
				dest: "dist/<%= pkg.version %>/css/<%= pkg.name %>-<%= pkg.version %>.css"

		uglify:
			options:
				mangle: true
			release:
				src: "<%= coffee.release.dest %>"
				dest: "dist/<%= pkg.version %>/js/<%= pkg.name %>-<%= pkg.version %>.min.js"

		cssmin:
			release:
				src: "<%= sass.release.dest %>"
				dest: "dist/<%= pkg.version %>/css/<%= pkg.name %>-<%= pkg.version %>.min.css"

		watch:
			release:
				files: ["<%= coffee.release.src %>", "<%= sass.release.src %>"]
				tasks: watchTasks
	
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-sass"
	grunt.loadNpmTasks "grunt-contrib-cssmin"
	
	grunt.registerTask "default", defaultTasks
	grunt.registerTask "dist", distTasks