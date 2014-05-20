ngAnnotate = angular.module "ngAnnotate", []

insertAt = (text, index, string)->
	return text.substr(0, index) + string + text.substr(index)

sortAnnotationsByEndIndex = (annotations)->
	return annotations.sort (a, b)->
		if a.endIndex < b.endIndex
			return -1
		else if a.endIndex > b.endIndex
			return 1
		return 0

parseAnnotations = (text, annotations = [], indexOffset = 0)->
	if annotations.length is 0
		return text
	annotations = sortAnnotationsByEndIndex annotations

	for i in [annotations.length - 1..0] by -1
		annotation = annotations[i];
		text = insertAt text, annotation.endIndex + indexOffset, "</span>"
		if annotation.children.length
			text = parseAnnotations text, annotation.children, annotation.startIndex + indexOffset
		text = insertAt text, annotation.startIndex + indexOffset, "<span class=\"ng-annotation ng-annotation-" + annotation.id + " " + annotation.type + "\" data-annotation-id=\"" + annotation.id + "\">"
	return text

createAnnotationPopup = (id, fields, showCancel = false)->
	$el = $ "<div class=\"ng-annotation-popup ng-annotation-popup-" + id + "\" />"
	for field in fields
		$label = $ "<label>" + field.label + "</label>"

		if field.type is "textarea"
			$field = $ "<textarea />",
				"class": field.classes
				name: field.name
				"ng-model": "annotation.data." + field.name

		else if field.type in ["number", "text", "date", "password"]
			$field = $ "<input />",
				type: field.type
				"class": field.classes
				name: field.name
				"ng-model": "annotation.data." + field.name
		
		$el.append $label
		$el.append $field

	$acceptButton = $("<button>Accept</button>").addClass "ng-annotate-accept"
	if showCancel
		$closeButton = $("<button>Cancel</button>").addClass "ng-annotate-cancel"
	else
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
	return new Date().getTime()

getAnnotationById = (annotations, aId)->
	for a in annotations
		if aId is a.id
			return a
		if a.children? and a.children.length > 0
			an = getAnnotationById a.children, aId
			if an isnt undefined
				return an

ngAnnotate.factory "Annotation", ->
	Annotation = (data)->

		angular.extend @,
			id: 0,
			startIndex: null
			endIndex: null
			data: {}
			type: ""
			children: []

		if data?
			angular.extend @, data

	return Annotation

ngAnnotate.directive "ngAnnotate", ($parse, $rootScope, $compile, $q, Annotation)->

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

				createAnnotation = (aId)->
					annotation = new Annotation
						id: aId
						type: "lilac"
					sel = window.getSelection()
					if sel.type isnt "Range"
						throw new Error "NG_ANNOTATE_NO_TEXT_SELECTED"
					range = sel.getRangeAt 0
					if range.startContainer.parentElement isnt range.endContainer.parentElement
						throw new Error "NG_ANNOTATE_PARTIAL_NODE_SELECTED"

					if range.startContainer.parentElement.nodeName is "SPAN" # Is a child annotation
						parentId = if (attrId = range.startContainer.parentElement.getAttribute("data-annotation-id"))? then parseInt(attrId, 10)
						if parentId is undefined
							throw new Error "NG_ANNOTATE_ILLEGAL_SELECTION"
						parentAnnotation = getAnnotationById $scope.annotations, parentId

						# Does this selection has any siblings?
						if parentAnnotation.children.length
							# Yup, find the previous sibling
							prevSiblingSpan = range.startContainer.previousSibling
							if prevSiblingSpan?
								prevSiblingId = if (attrId = prevSiblingSpan.getAttribute("data-annotation-id"))? then parseInt(attrId, 10)
								if not prevSiblingId?
									throw new Error "NG_ANNOTATE_ILLEGAL_SELECTION"
								
								prevAnnotation = getAnnotationById parentAnnotation.children, prevSiblingId
								annotation.startIndex = prevAnnotation.endIndex + range.startOffset
								annotation.endIndex = prevAnnotation.endIndex + range.endOffset
						else
							# Nope
							annotation.startIndex = range.startOffset
							annotation.endIndex = range.endOffset

						parentAnnotation.children.push annotation
					else
						# Does this selection has any siblings?
						if $scope.annotations.length
							# Yup, find the previous sibling
							prevSiblingSpan = range.startContainer.previousSibling
							if prevSiblingSpan?
								prevSiblingId = if (attrId = prevSiblingSpan.getAttribute("data-annotation-id"))? then parseInt(attrId, 10)
								if not prevSiblingId?
									throw new Error "NG_ANNOTATE_ILLEGAL_SELECTION"
								
								prevAnnotation = getAnnotationById $scope.annotations, prevSiblingId
								annotation.startIndex = prevAnnotation.endIndex + range.startOffset
								annotation.endIndex = prevAnnotation.endIndex + range.endOffset
						else
							# Nope
							annotation.startIndex = range.startOffset
							annotation.endIndex = range.endOffset

						$scope.annotations.push annotation
					return annotation

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

					try
						annotation = createAnnotation annotationId
						$scope.$apply()
						$annotationElement = element.find(".ng-annotation-" + annotationId)
					catch ex
						$scope.onAnnotateError ex
						return

					# Create and fill the annotationpopups model with data specified by user
					popupScope = $rootScope.$new()
					popupScope.annotation = new Annotation()
					for field in options.fields
						popupScope.annotation.data[field.name] = field.defaultValue

					offset = $annotationElement.offset()
					width = $annotationElement.innerWidth()
					height = $annotationElement.innerHeight()

					$popup = createAnnotationPopup annotationId, options.fields

					$compile($popup.get(0)) popupScope, ($el, scope)->
						$el.appendTo("body");
						popupHeight = $el.innerHeight()
						$el.css
							left: offset.left - 320,
							top: offset.top - (height / 2) - (popupHeight / 2)
						$el.fadeIn("slow");

						$el.find(".ng-annotate-accept").on "click", (event)->
							event.preventDefault()
							$scope.onAnnotate scope.annotation
							destroyAnnotationPopup $el, scope

						$el.find(".ng-annotate-close, .ng-annotate-cancel").on "click", (event)->
							event.preventDefault()
							destroyAnnotationPopup $el, scope
	}