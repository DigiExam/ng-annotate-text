# ng-annotate-text demo

This is the source code of a demo implementation of [ng-annotate-text](https://github.com/DigiExam/ng-annotate-text/), an AngularJS directive for annotating text.

Visit [digiexam.github.io/ng-annotate-text](http://digiexam.github.io/ng-annotate-text/) to try the demo.

## Get the demo code and play with it

1. Install NodeJS ([nodejs.org](http://nodejs.org/))
2. Install Gulp globally: `npm install -g gulp`
3. Fork the repo and clone it. ([How to do it with GitHub.](https://help.github.com/articles/fork-a-repo))
4. Go into the project folder: `cd ng-annotate-text`
5. Check out the gh-pages branch: `git checkout gh-pages`
6. Install the project dependencies: `npm install`
7. Build the project files and launch a web server: `gulp serve` 

To make development of ng-annotate-text easier you can check out the `master` branch in one directory and the `gh-pages` branch (the demo) in another, then symlink the unstable files from `master` into the `lib` directory in `gh-pages`, and change the includes in `index.html` to use the unstable versions.

## Browser compatibility for the demo

Chrome, Firefox, Safari and IE9+

Autoprefixer rule: last 2 versions, ie >= 9, Firefox ESR

## License

Licensed under [CC-BY-NC](https://tldrlegal.com/license/creative-commons-attribution-noncommercial-(cc-nc))

Copyright (C) 2014 DigiExam
