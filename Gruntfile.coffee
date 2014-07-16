module.exports = (grunt) ->
	# Release
	distTasks = ["coffee:release", "sass:release", "uglify", "cssmin", "copy:release"]	

	# Development
	defaultTasks = ["coffee:development", "sass:development"]
	watchTasks = defaultTasks
	serveTasks = ["connect", "coffee:development", "sass:development", "watch"]

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

		uglify:
			options:
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
			release:
				files: ["<%= coffee.release.src %>", "<%= sass.release.src %>"]
				tasks: watchTasks

		connect:		
			server:
				options:
					port: 3000
					hostname: "localhost"
					open: "http://localhost:3000/example-app/"

	
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-sass"
	grunt.loadNpmTasks "grunt-contrib-cssmin"
	grunt.loadNpmTasks "grunt-contrib-connect"
	grunt.loadNpmTasks "grunt-contrib-copy"
	
	grunt.registerTask "default", defaultTasks
	grunt.registerTask "dist", distTasks
	grunt.registerTask "serve", serveTasks
