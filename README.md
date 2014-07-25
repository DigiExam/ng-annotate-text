# ng-annotate

ng-annotate is a library to annotate texts in AngularJS.

![Screenshot](screenshot.png)

## Demo

[Try a demo of ng-annotate.](http://blog.digiexam.se/annotate-test/)

## Attributes

Attribute | Default value | Description
--- | --- | ---
popup-offset | 10 | Position the popup editor away form its annotation and the window edges by this many pixels.

## Event listeners

Event | Description
--- | ---
ngAnnotateText.clearPopups | Clears any open popup or tooltip

## Getting started with development

1. Install NodeJS ([nodejs.org](http://nodejs.org/))
2. Install Gulp globally: `npm install -g gulp`
3. Fork the repo and clone it. ([How to do it with GitHub.](https://help.github.com/articles/fork-a-repo))
4. Go into the project folder: `cd ng-annotate`
5. Install the project dependencies: `npm install`
6. Build the project files: `gulp`
  * Build them whenever they change: `gulp watch`

To make development of ng-annotate easier you can check out the `master` branch in one directory and the `gh-pages` branch in another, then symlink the dist files from `master` into the `lib` directory in `gh-pages`, and change the includes in `index.html` to use those versions.

## Browser compatability

Chrome, Firefox, Safari and IE9+

Autoprefixer rule: last 2 versions, ie >= 9, Firefox ESR

## Annotation colors

Main annotation class is `.ng-annotation`.
An annotation is extended by adding a type class to `.ng-annotation`.

Available default type classes are:
	
	.ng-annotation-type-red - Sets background to red, color to black and border-color to red.
	.ng-annotation-type-green - Sets background to green, color to black and border-color to green.
	.ng-annotation-type-blue - Sets background to blue, color to black and border-color to blue.
	.ng-annotation-type-pink - Sets background to pink, color to black and border-color to pink.
	.ng-annotation-type-yellow - Sets background to yellow, color to black and border-color to yellow. 
	.ng-annotation-type-aqua - Sets background to aqua, color to black and border-color to aqua.

## License

Licensed under CC-BY-NC

https://tldrlegal.com/license/creative-commons-attribution-noncommercial-(cc-nc)

Copyright (C) 2014 DigiExam
