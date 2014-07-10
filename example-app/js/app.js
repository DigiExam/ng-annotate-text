var app = angular.module("app", ["ngAnnotate"]);

app.controller("AnnotationController", function($scope, $timeout)
{
	$scope.annotationColours = [
		{ name: "Red", value: "red" },
		{ name: "Green", value: "green" },
		{ name: "Blue", value: "blue" },
		{ name: "Yellow", value: "yellow" },
		{ name: "Pink", value: "pink" },
		{ name: "Aqua", value: "aqua" }
	];

	$scope.close = function()
	{
		$scope.$close();
	};

	$scope.reject = function()
	{
		$scope.$reject()
	};

	$timeout(function() { $scope.$reposition(); });
});

app.controller("MainController", function($scope, $timeout, NGAnnotation)
{
	$scope.texts = []
	$scope.texts[0] = "The Stockholm School of Economics (SSE) or Handelshögskolan i Stockholm (HHS) is one of the leading European business schools. SSE is a private business school that receives most of its financing from private sources. SSE offers bachelors, masters and MBA programs, along with highly regarded PhD programs and extensive Executive Education (customized and open programs).\r\rSSE's Masters in Management program is ranked no. 18 worldwide by the Financial Times.[1] QS ranks SSE no.26 among universities in the field of economics worldwide\r\rSSE is accredited by EQUIS certifying that all of its main activities, teaching as well as research, are of the highest international standards. SSE is also the Swedish member institution of CEMS together with universities such as London School of Economics, Copenhagen Business School, Tsinghua University, Bocconi University, HEC Paris and the University of St. Gallen.\r\rSSE has founded sister organizations: SSE Riga in Riga, Latvia, and SSE Russia in St Petersburg, Russia. It also operates a research institute in Tokyo, Japan; the EIJS (European Institute of Japanese Studies).";
	
	$scope.annotations = [];
	$scope.annotations[0] = [new NGAnnotation({ startIndex: 0, endIndex: 39, type: "green", data: { comment:  "Well written!", points: 2 }})]

	$scope.options = {
		readonly: false,
		popupTemplateUrl: "partials/annotation.html",
		popupController: "AnnotationController",
		tooltipTemplateUrl: "partials/annotation-tooltip.html",
		tooltipController: "AnnotationController"
	};

	$scope.onAnnotate = function($annotation)
	{
		console.log($annotation);
	};

	$scope.onAnnotateError = function($ex)
	{
		if($ex.message == "NG_ANNOTATE_PARTIAL_NODE_SELECTED")
			alert("Invalid selection.");
		else
			throw $ex
	}

	$scope.annotationsAsFlatList = function(source) {
		var annotations = []

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
		};

		return annotations;
	}
});