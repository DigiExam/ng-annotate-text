angular.module("app", ["ngAnnotate"])

	.controller("AnnotationController", function($scope, $timeout) {
		$scope.annotationColours = [
			{ name: "Red", value: "red" },
			{ name: "Green", value: "green" },
			{ name: "Blue", value: "blue" },
			{ name: "Yellow", value: "yellow" },
			{ name: "Pink", value: "pink" },
			{ name: "Aqua", value: "aqua" }
		];

		$scope.templates = [
			{
				type: "red",
				comment: "Grammar mistake",
				points: -1
			},
			{
				type: "aqua",
				comment: "Spelling mistake",
				points: -1
			}
		];

		$scope.useTemplate = function(template) {
			if (template.type != null) {
				$scope.$annotation.type = template.type;
			}

			if (template.comment != null) {
				$scope.$annotation.data.comment = template.comment;
			}

			if (template.points !== null) {
				$scope.$annotation.data.points = template.points;
			}

			$scope.$close();
		};

		$scope.useColor = function(color) {
			if (color.value != null) {
				$scope.$annotation.type = color.value;
			}
		};

		$scope.isActiveColor = function(color) {
			return color && color.value === $scope.$annotation.type;
		};

		$scope.close = function() {
			$scope.$close();
		};

		$scope.reject = function() {
			$scope.$reject()
		};

		$timeout(function() { $scope.$reposition(); });
	})

	.controller("MainController", function($scope, $timeout, NGAnnotation) {
		$scope.demoTexts = [
			"The Stockholm School of Economics (SSE) or Handelshögskolan i Stockholm (HHS) is one of the leading European business schools. SSE is a private business school that receives most of its financing from private sources. SSE offers bachelors, masters and MBA programs, along with highly regarded PhD programs and extensive Executive Education (customized and open programs).\r\rSSE's Masters in Management program is ranked no. 18 worldwide by the Financial Times.[1] QS ranks SSE no.26 among universities in the field of economics worldwide\r\rSSE is accredited by EQUIS certifying that all of its main activities, teaching as well as research, are of the highest international standards. SSE is also the Swedish member institution of CEMS together with universities such as London School of Economics, Copenhagen Business School, Tsinghua University, Bocconi University, HEC Paris and the University of St. Gallen.\r\rSSE has founded sister organizations: SSE Riga in Riga, Latvia, and SSE Russia in St Petersburg, Russia. It also operates a research institute in Tokyo, Japan; the EIJS (European Institute of Japanese Studies)."
		];
		$scope.annotations = [
			[
				new NGAnnotation({
					startIndex: 0,
					endIndex: 39,
					type: "green",
					data: { comment:  "Well written!", points: 2 }
				})
			]
		];

		$scope.options = {
			readonly: false,
			popupTemplateUrl: "partials/annotation.html",
			popupController: "AnnotationController",
			tooltipTemplateUrl: "partials/annotation-tooltip.html",
			tooltipController: "AnnotationController"
		};

		$scope.onAnnotate = function($annotation) {
			if (console.log) {
				console.log($annotation);
			}
		};

		$scope.onAnnotateError = function($ex) {
			if ($ex.message == "NG_ANNOTATE_PARTIAL_NODE_SELECTED") {
				alert("Invalid selection.");
			} else {
				throw $ex
			}
		};

		$scope.onEditorShow = function($el) {
			// Focus the first input or textarea
			var firstInput = $el.find("input, textarea").eq(0).focus();
			firstInput && firstInput[0].select();
		};

		$scope.annotationsAsFlatList = function(source) {
			var annotations = [];

			if (source == null) {
				source = $scope.annotations[0]
			}

			for (var i = 0; i < source.length; i++) {
				var a = source[i];

				if (a.data.points != null || a.data.comment != null) {
					annotations.push(a);
				}

				var children = $scope.annotationsAsFlatList(a.children);
				annotations = annotations.concat(children);
			}

			return annotations;
		}
	});
