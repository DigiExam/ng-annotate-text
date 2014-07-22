angular.module("app", ["ngAnnotate"])

	.controller "AnnotationController", ($scope, $timeout) ->
		$scope.annotationColours = [
			{ name: "Red", value: "red" }
			{ name: "Green", value: "green" }
			{ name: "Blue", value: "blue" }
			{ name: "Yellow", value: "yellow" }
			{ name: "Pink", value: "pink" }
			{ name: "Aqua", value: "aqua" }
		]

		$scope.templates = [
			{
				type: "red"
				comment: "Grammar mistake"
				points: -1
			}
			{
				type: "aqua"
				comment: "Spelling mistake"
				points: -1
			}
		]

		$scope.useTemplate = (template) ->
			if template.type isnt null
				$scope.$annotation.type = template.type
			if template.comment isnt null
				$scope.$annotation.data.comment = template.comment
			if template.points isnt null
				$scope.$annotation.data.points = template.points
			$scope.$close()
			return

		$scope.useColor = (color) ->
			if color.value isnt null
				$scope.$annotation.type = color.value
			return

		$scope.isActiveColor = (color) ->
			color and color.value is $scope.$annotation.type

		$scope.close = -> $scope.$close()
		$scope.reject = -> $scope.$reject()

		return

	.controller "MainController", ($scope, $timeout, NGAnnotation) ->
		$scope.demoTexts = [
			"The Stockholm School of Economics (SSE) or Handelshögskolan i Stockholm (HHS) is one of the leading European business schools. SSE is a private business school that receives most of its financing from private sources. SSE offers bachelors, masters and MBA programs, along with highly regarded PhD programs and extensive Executive Education (customized and open programs).\r\rSSE's Masters in Management program is ranked no. 18 worldwide by the Financial Times.[1] QS ranks SSE no.26 among universities in the field of economics worldwide\r\rSSE is accredited by EQUIS certifying that all of its main activities, teaching as well as research, are of the highest international standards. SSE is also the Swedish member institution of CEMS together with universities such as London School of Economics, Copenhagen Business School, Tsinghua University, Bocconi University, HEC Paris and the University of St. Gallen.\r\rSSE has founded sister organizations: SSE Riga in Riga, Latvia, and SSE Russia in St Petersburg, Russia. It also operates a research institute in Tokyo, Japan; the EIJS (European Institute of Japanese Studies)."
		]

		$scope.annotations = [
			[
				new NGAnnotation
					startIndex: 0
					endIndex: 39
					type: "green"
					data:
						comment: "Well written!"
						points: 2
			]
		]

		$scope.options =
			readonly: false
			popupTemplateUrl: "partials/annotation.html"
			popupController: "AnnotationController"
			tooltipTemplateUrl: "partials/annotation-tooltip.html"
			tooltipController: "AnnotationController"

		$scope.onAnnotate = ($annotation) ->
			console && console.log $annotation
			return

		$scope.onAnnotateError = ($ex) ->
			if $ex.message == "NG_ANNOTATE_PARTIAL_NODE_SELECTED"
				alert "Invalid selection."
			else
				throw $ex

		$scope.onEditorShow = ($el) ->
			# Focus the first input or textarea
			firstInput = $el.find("input, textarea").eq(0).focus()
			firstInput && firstInput[0].select()

		$scope.hasPoints = (points) ->
			_isNaN = Number.isNaN || isNaN
			typeof points is "number" and points isnt 0 and not _isNaN points

		$scope.hasComment = (comment) ->
			typeof comment is "string" and comment.length > 0

		$scope.annotationsAsFlatList = (annotations = $scope.annotations[0]) ->
			if not annotations.length
				[]
			else
				annotations
					.map((annotation) ->
						arr = []
						if $scope.hasPoints(annotation.data.points) and $scope.hasComment(annotation.data.comment)
							arr.push annotation
						if annotation.children and annotation.children.length
							arr = arr.concat $scope.annotationsAsFlatList annotation.children
						arr
					)
					.reduce((prev, current) ->
						prev.concat current
					)
