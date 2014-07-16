# ng-annotate

ng-annotate is a library to annotate texts in AngularJS.

![Screenshot](http://i.imgur.com/IHjxXn1.png?1)

## Demo

To try a demo, go to: http://blog.digiexam.se/annotate-test/

## Getting started with development

- Install NodeJS
- Run **npm install -g grunt-cli**
- Run **npm install** in the ng-annotate folder
- Run **grunt serve** 

**grunt serve** will launch the example application which also currently also is the only use documentation.

## Browser compatability

Chrome, Firefox, Safari and IE9+

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
