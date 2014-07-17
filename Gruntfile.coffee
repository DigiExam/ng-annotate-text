module.exports = (grunt) ->
	defaultTasks = ["bower", "coffee", "sass", "autoprefixer"]
	cssWatchTasks = ["sass", "autoprefixer"]
	jsWatchTasks = ["coffee"]
	serveTasks = ["bower", "connect", "watch"]

	grunt.initConfig
		pkg: grunt.file.readJSON "package.json"

		bower:
			options:
				# Depends on old bower that is broken
				install: false
				layout: "byComponent"
			install: {}

		coffee:
			#options:
				#sourceMap: true
			main:
				src: "src/main.coffee"
				dest: "dist/main.js"

		sass:
			main:
				src: "src/main.scss"
				dest: "dist/main.css"

		autoprefixer:
			options:
				browsers: [
					"last 2 versions"
					"ie >= 9"
					"Firefox ESR"
				]
			main:
				src: "<%= sass.main.dest %>"

		uglify:
			options:
				# Mangle will shorten variable names which breaks the AngularJS dependency injection.
				mangle: false
			main:
				src: "dist/main.js"
				dest: "dist/main.min.js"

		cssmin:
			main:
				src: "dist/main.css"
				dest: "dist/main.min.css"

		watch:
			options:
				atBegin: true
			css:
				files: ["<%= sass.main.src %>"]
				tasks: cssWatchTasks
			js:
				files: ["<%= coffee.main.src %>"]
				tasks: jsWatchTasks

		connect:
			server:
				options:
					port: 3000
					hostname: "localhost"
					open: "http://localhost:3000/"

	grunt.loadNpmTasks "grunt-bower-task"
	grunt.loadNpmTasks "grunt-contrib-uglify"
	grunt.loadNpmTasks "grunt-contrib-coffee"
	grunt.loadNpmTasks "grunt-contrib-watch"
	grunt.loadNpmTasks "grunt-contrib-sass"
	grunt.loadNpmTasks "grunt-contrib-cssmin"
	grunt.loadNpmTasks "grunt-contrib-connect"
	grunt.loadNpmTasks "grunt-autoprefixer"

	grunt.registerTask "default", defaultTasks
	grunt.registerTask "serve", serveTasks
