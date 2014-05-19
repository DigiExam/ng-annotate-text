ngAnnotate = angular.module "ngAnnotate", []

parseAnnotations = (text, annotations)->
	annotations.sort (a, b)->
		if a.endIndex < b.endIndex
			return -1
		else if a.endIndex > b.endIndex
			return 1
		return 0

	for i in [annotations.length - 1..0] by -1
		a = annotations[i]

	return text

createAnnotationPopup = (id, fields)->
	$el = $ "<div class=\"ng-annotation-popup ng-annotation-popup-" + id + "\" />"
	for field in fields
		$label = $ "<label>" + field.label + "</label>"

		if field.type is "textarea"
			$field = $ "<textarea />",
				"class": field.classes
				name: field.name
				"ng-model": "annotation." + field.name

		else if field.type in ["number", "text", "date", "password"]
			$field = $ "<input />",
				type: field.type
				"class": field.classes
				name: field.name
				"ng-model": "annotation." + field.name
		
		$el.append $label
		$el.append $field

	$acceptButton = $("<button>Accept</button>").addClass "ng-annotate-accept"
	$closeButton = $("<button>Close</button>").addClass "ng-annotate-close"
	$el.append [$acceptButton, $closeButton]
	return $el

removeAnnotation = ($element)->
	$element.unwrap()

generateId = ->
	return Math.floor Math.random() * 100000

getSel = ->
	sel = window.getSelection()
	if sel.type isnt "Range"
		throw new Error "NG_ANNOTATE_NO_TEXT_SELECTED"
	return sel

surroundSelection = (node)->
	sel = getSel()
	range = sel.getRangeAt 0
	try
		range.surroundContents node
	catch ex
		if ex.name is "InvalidStateError"
			throw new Error "NG_ANNOTATE_PARTIAL_NODE_SELECTED"
		throw ex

ngAnnotate.directive "ngAnnotate", ($parse, $rootScope, $compile, $timeout)->

	return {
		restrict: "A"
		link: ($scope, element, attrs)->
			options =
				annotations: "annotations"
				fields: [
					{
						name: "comment"
						label: "Comment"
						classes: "ng-annotation-comment"
						type: "textarea"
						defaultValue: "\"\""
					}
				]

			annotations = []
			options = angular.extend options, $parse(attrs["ngAnnotate"])($scope)
			onAnnotate = $parse attrs["ngAnnotateOnAnnotation"]
			onAnnotateError = $parse attrs["ngAnnotateOnError"]

			element.on "mousedown", -> mouseDown = containedToElement = true
			element.on "mouseleave", -> if mouseDown then containedToElement = false
			element.on "mouseenter", -> if mouseDown then containedToElement = true

			element.on "mouseup", (event)->
				if !containedToElement
					return
				mouseDown = false;

				event.preventDefault()

				# Generate a random ID to assign this annotation
				annotationId = generateId()

				# Create and fill the annotationpopups model with data specified by user
				popupScope = $rootScope.$new()
				popupScope.annotation = {}
				for field in options.fields
					popupScope.annotation[field.name] = field.defaultValue

				$element = $ "<span />",
					"class": "ng-annotation ng-annotation-" + annotationId

				try
					surroundSelection $element.get(0)
				catch ex
					$timeout -> onAnnotateError($scope, { $ex: ex })
					return

				offset = $element.offset()
				width = $element.innerWidth()
				height = $element.innerHeight()

				$popup = createAnnotationPopup annotationId, options.fields
				$popup.css
					left: element.offset().left - 320,
					top: offset.top - (height / 2) - ($popup.innerHeight() / 2)

				$compile($popup.get(0)) popupScope, ($el, scope)->
					$el.appendTo("body");
					$el.fadeIn("slow");

					$el.find(".ng-annotate-accept").on "click", (event)->
						event.preventDefault()
						$timeout -> onAnnotate $scope, { $annotation: scope.annotation }

					$el.find(".ng-annotate-close").on "click", (event)->
						event.preventDefault()
						removeAnnotation $element
						$el.find("button").off "click"
						$el.fadeOut "slow", ->
							scope.$destroy()
							#$el.remove()
	}