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

createAnnotationPopup = (id)->
	$el = angular.element "<div class=\"ng-annotation-popup ng-annotation-popup-" + id + "\" />"
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
		if a.children.length > 0
			an = getAnnotationById a.children, aId
			if an isnt undefined
				return an

removeAnnotation = (id, annotations)->
	for a, i in annotations
		if a.id is id
			annotations.splice i, 1
			return
		if a.children.length
			removeAnnotation id, a.children

ngAnnotate.factory "NGAnnotatePopupStack", ->
	NGAnnotatePopupStack = ->
		stack = []
		angular.extend @,
			push: (key, item)->
				stack.push
					key: key,
					value: item
			top: ->
				return stack[stack.length - 1]
			remove: (key)->
				for i in [stack.length - 1..0] by -1
					item = stack[i]
					if item.key is key
						stack.splice i, 1
			clear: ->
				stack = []

	return NGAnnotatePopupStack

ngAnnotate.factory "NGAnnotation", ->
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

ngAnnotate.directive "ngAnnotate", ($rootScope, $compile, $http, $q, NGAnnotation, NGAnnotatePopupStack)->
	return {
		restrict: "A"
		scope:
			text: "="
			annotations: "="
			options: "="
			onAnnotate: "="
			onAnnotateError: "="
		compile: (tElement, tAttrs, transclude)->

			return ($scope, element, attrs)->
				popupStack = new NGAnnotatePopupStack()

				# Cache the template when we fetch it
				templateData = ""

				onAnnotationsChange = ->
					if !$scope.text.length
						return
					t = parseAnnotations $scope.text, $scope.annotations
					tElement.html t

				# Annotation parsing
				$scope.$watch "annotations", onAnnotationsChange, true

				# Setting options
				options =
					popupTemplateUrl: ""
				options = angular.extend options, $scope.options

				getTemplate = (url)->
					if templateData.length
						deferred = $q.defer()
						deferred.resolve templateData
						return deferred.promise
					
					return $http.get(url).then (response)->
						return response.data

				createAnnotation = (aId)->
					annotation = new NGAnnotation
						id: aId
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

						annotationParentCollection = parentAnnotation.children
					else
						annotationParentCollection = $scope.annotations

					# Does this selection has any siblings?
					if annotationParentCollection.length
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

					annotationParentCollection.push annotation
					return annotation

				onSelect = (event)->
					# Generate a random ID to assign this annotation
					annotationId = generateId()

					try
						annotation = createAnnotation annotationId
						$scope.$apply()
						$span = element.find(".ng-annotation-" + annotationId)
					catch ex
						$scope.onAnnotateError ex
						return

					spanOffsetTop = $span.offset().top
					spanHeight = $span.innerHeight()
					
					getTemplatePromise = getTemplate options.popupTemplateUrl
					getTemplatePromise.then (template)->
						$popup = createAnnotationPopup annotationId
						popupScope = $rootScope.$new()
						popupScope.isNew = true

						popupScope.annotation = annotation
						popupScope.$reject = ->
							removeAnnotation annotationId, $scope.annotations
							destroyAnnotationPopup $popup, popupScope

						popupScope.$close = ->
							$scope.onAnnotate popupScope.annotation
							destroyAnnotationPopup $popup, popupScope

						$popup.appendTo "body"
						$compile(angular.element(template)) popupScope, ($el, scope)->
							$popup.html $el
							popupHeight = $popup.innerHeight()
							$popup.css
								left: element.offset().left - 320,
								top: spanOffsetTop + (spanHeight / 2) - (popupHeight / 2)
							$popup.fadeIn "slow"

				onClick = (event)->
					$target = angular.element event.target
					targetId = if (attrId = $target.attr("data-annotation-id"))? then parseInt(attrId, 10)

					if not targetId?
						return

					spanOffsetTop = $target.offset().top
					spanHeight = $target.innerHeight()

					getTemplatePromise = getTemplate options.popupTemplateUrl
					getTemplatePromise.then (template)->
						$popup = createAnnotationPopup targetId
						popupScope = $rootScope.$new()
						popupScope.isNew = false

						popupScope.annotation = getAnnotationById $scope.annotations, targetId

						popupScope.$reject = ->
							removeAnnotation targetId, $scope.annotations
							destroyAnnotationPopup $popup

						popupScope.$close = ->
							$scope.onAnnotate popupScope.annotation
							destroyAnnotationPopup $popup, popupScope

						$popup.appendTo "body"
						$compile(angular.element(template)) popupScope, ($el, scope)->
							$popup.html $el
							popupHeight = $popup.innerHeight()
							$popup.css
								left: element.offset().left - 320,
								top: spanOffsetTop + (spanHeight / 2) - (popupHeight / 2)
							$popup.fadeIn "slow"

				onMouseOver = (event)->


				element.on "mouseup", (event)->
					# We need to determine if the user actually selected something
					# or if he just clicked on an annotation
					selection = window.getSelection()
					if selection.type is "Range"
						# User has selected something
						onSelect event
					else if selection.type is "Caret" and event.target.nodeName is "SPAN"
						onClick event
	}