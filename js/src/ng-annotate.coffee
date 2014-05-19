ngAnnotate = angular.module "ngAnnotate", []

insertAt = (text, index, string)->
	return text.substr(0, index) + string + text.substr(index)

parseAnnotations = (text, annotations = [], indexOffset = 0)->
	if annotations.length is 0
		return text
	annotations.sort (a, b)->
		if a.endIndex < b.endIndex
			return -1
		else if a.endIndex > b.endIndex
			return 1
		return 0

	for i in [annotations.length - 1..0] by -1
		annotation = annotations[i];
		text = insertAt text, annotation.endIndex + indexOffset, "</span>"
		if annotation.children? and annotation.children.length
			text = parseAnnotations text, annotation.children, annotation.startIndex
		text = insertAt text, annotation.startIndex + indexOffset, "<span class=\"ng-annotation ng-annotation-" + annotation.id + " " + annotation.type + "\" data-annotation-id=\"" + annotation.id + "\">"
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

destroyAnnotationPopup = ($popup, scope)->
	$popup.find("button").off "click"
	$popup.fadeOut "slow", ->
		scope.$destroy()
		$popup.remove()

showAnnotation = ($element)->

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

ngAnnotate.factory "Annotation", ->
	Annotation = (data)->

		angular.extend @,
			id: 0,
			startIndex: null
			endIndex: null
			data: {}
			children: []

		if data?
			angular.extend @, data

	return Annotation

ngAnnotate.directive "ngAnnotate", ($parse, $rootScope, $compile, $timeout, Annotation)->

	return {
		restrict: "A"
		scope:
			text: "="
			annotations: "="
			options: "="
			onAnnotate: "="
			onAnnotateError: "="
		compile: (tElement, tAttrs, transclude)->
			text = tElement.text().trim()
			return ($scope, element, attrs)->
				# Annotation parsing
				$scope.$watch "annotations", ->
					if !$scope.text.length
						return
					t = parseAnnotations $scope.text, $scope.annotations
					tElement.html t
				, true

				options =
					fields: [
						{
							name: "comment"
							label: "Comment"
							classes: "ng-annotation-comment"
							type: "textarea"
							defaultValue: "\"\""
						}
					]
				options = angular.extend options, $scope.options

				mouseDown = false
				containedToElement = false

				element.on "mousedown", -> mouseDown = containedToElement = true
				element.on "mouseleave", -> if mouseDown then containedToElement = false
				element.on "mouseenter", -> if mouseDown then containedToElement = true

				element.on "mouseup", (event)->
					if !containedToElement
						return
					mouseDown = false

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
						$scope.onAnnotateError ex
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
							$scope.onAnnotate scope.annotation
							destroyAnnotationPopup $el, scope

						$el.find(".ng-annotate-close").on "click", (event)->
							event.preventDefault()
							destroyAnnotationPopup $el, scope
	}