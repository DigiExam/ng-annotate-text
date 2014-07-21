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
		text = insertAt text, annotation.startIndex + indexOffset, "<span class=\"ng-annotate-annotation ng-annotate-" + annotation.id + " ng-annotate-type-" + annotation.type + "\" data-annotation-id=\"" + annotation.id + "\">"
	return text

getAnnotationById = (annotations, aId)->
	for a in annotations
		if aId is a.id
			return a
		if a.children.length > 0
			an = getAnnotationById a.children, aId
			if an isnt undefined
				return an

smartPositionBeforeOrAfterAnchor = (targetSize, anchorStart, anchorEnd, viewportSize, scrollDistance, offset = 0) ->
	pos = null
	if anchorStart - offset >= targetSize
		# Before anchor
		pos = scrollDistance + anchorStart - offset - targetSize
	else if viewportSize - anchorEnd - offset >= targetSize
		# After anchor
		pos = scrollDistance + anchorEnd + offset
	pos

smartPositionCenterOnAnchor = (targetSize, anchorSize, anchorStart, viewportSize, scrollDistance, offset = 0) ->
	pos = scrollDistance + anchorStart + (anchorSize / 2) - (targetSize / 2)
	Math.max(scrollDistance + offset, Math.min(pos, scrollDistance + viewportSize - targetSize - offset))

smartPosition = (targetEl, anchorEl, offset = 0, preferredAxis = 'x') ->
	if not (targetEl or anchorEl)
		return

	targetBox = targetEl.getBoundingClientRect()
	anchorBox = anchorEl.getBoundingClientRect()
	viewportWidth = window.innerWidth
	viewportHeight = window.innerHeight
	scrollTop = document.body.scrollTop
	scrollLeft = document.body.scrollLeft

	posLeft = null
	posTop = null

	# Find which side has free space and position it there
	if not (targetBox.width > 0 and targetBox.height > 0)
		# Workaround if the target doesn't have width and height
		# FIXME: don't use this to prevent some error or what it was, do a proper fix... mjeh..
		posLeft = scrollLeft
		posTop = scrollTop
	else
		cachePosLeft = smartPositionBeforeOrAfterAnchor targetBox.width, anchorBox.left, anchorBox.right, viewportWidth, scrollLeft, offset
		cachePosTop = smartPositionBeforeOrAfterAnchor targetBox.height, anchorBox.top, anchorBox.bottom, viewportHeight, scrollTop, offset
		if preferredAxis is 'x'
			posLeft = cachePosLeft
			if posLeft is null
				posTop = cachePosTop
		else
			posTop = cachePosTop
			if posTop is null
				posLeft = cachePosLeft

	# Center on null positions
	if posLeft is null and posTop is null
		# Center in viewport
		posLeft = scrollLeft + (viewportWidth / 2) - (targetBox.width / 2)
		posTop = scrollTop + (viewportHeight / 2) - (targetBox.height / 2)
	else if posLeft is null
		# Center on element from left
		posLeft = smartPositionCenterOnAnchor targetBox.width, anchorBox.width, anchorBox.left, viewportWidth, scrollLeft, offset
	else if posTop is null
		# Center on element from top
		posTop = smartPositionCenterOnAnchor targetBox.height, anchorBox.height, anchorBox.top, viewportHeight, scrollTop, offset

	angular.element(targetEl).css
		top: Math.round(posTop) || 0
		left: Math.round(posLeft) || 0

	return

ngAnnotate.factory "NGAnnotatePopup", ->
	NGAnnotatePopup = (scope)->

		angular.extend @,
			scope: scope
			$el: angular.element "<div class=\"ng-annotate-popup\" />"
			$anchor: null

			show: (cb = angular.noop, speed = "fast")->
				@$el.fadeIn speed, cb
				if typeof scope.onEditorShow is "function"
					scope.onEditorShow @$el

			hide: (cb = angular.noop, speed = "fast")->
				@$el.fadeOut speed, cb
				if typeof scope.onEditorHide is "function"
					scope.onEditorHide @$el

			isVisible: ->
				return @$el.is ":visible"

			destroy: (cb = angular.noop)->
				scope = @scope
				$el = @$el
				@hide ->
					cb()
					scope.$destroy()
					$el.remove()

	return NGAnnotatePopup

ngAnnotate.factory "NGAnnotateTooltip", ->
	NGAnnotateTooltip = (scope)->

		angular.extend @,
			scope: scope,
			$el: angular.element "<div class=\"ng-annotate-tooltip\" />"
			$anchor: null

			show: (cb = angular.noop, speed = "fast")->
				@$el.fadeIn speed, cb

			hide: (cb = angular.noop, speed = "fast")->
				@$el.fadeOut speed, cb

			isVisible: ->
				return @$el.is ":visible"

			destroy: (cb = angular.noop)->
				scope = @scope
				$el = @$el
				@hide ->
					cb()
					scope.$destroy()
					$el.remove()

			stopDestroy: ->
				@$el.stop(true).show("fast")

ngAnnotate.factory "NGAnnotation", ->
	Annotation = (data)->

		angular.extend @,
			id: new Date().getTime(),
			startIndex: null
			endIndex: null
			data: {points: 0}
			type: ""
			children: []

		if data?
			angular.extend @, data

	return Annotation

ngAnnotate.directive "ngAnnotate", ($rootScope, $compile, $http, $q, $controller, $sce, NGAnnotation, NGAnnotatePopup, NGAnnotateTooltip)->
	return {
		restrict: "E"
		scope:
			text: "="
			annotations: "="
			options: "="
			onAnnotate: "="
			onAnnotateDelete: "="
			onAnnotateError: "="
			onEditorShow: "="
			onEditorHide: "="
			popupOffset: "="
		template: "<p ng-bind-html=\"content\"></p>"
		replace: true
		compile: (tElement, tAttrs, transclude)->
			LEFT_MARGIN = -10
			POPUP_OFFSET = 10

			return ($scope, element, attrs)->
				activePopup = null
				activeTooltip = null

				# Cache the template when we fetch it
				popupTemplateData = ""
				tooltipTemplateData = ""

				onAnnotationsChange = ->
					if not $scope.text? or !$scope.text.length
						return
					t = parseAnnotations $scope.text, $scope.annotations
					$scope.content = $sce.trustAsHtml t

				# Annotation parsing
				$scope.$watch "text", onAnnotationsChange
				$scope.$watch "annotations", onAnnotationsChange, true

				# Setting options
				options =
					readonly: false
					popupController: ""
					popupTemplateUrl: ""
					tooltipController: ""
					tooltipTemplateUrl: ""
				options = angular.extend options, $scope.options

				clearPopup = ->
					if not activePopup?
						return
					tId = activePopup.scope.$annotation.id
					activePopup.destroy ->
						if activePopup.scope.$annotation.id is tId
							activePopup = null

				clearTooltip = ->
					tooltip = activeTooltip
					if not tooltip?
						return
					tooltip.destroy ->
						if activeTooltip is tooltip
							activeTooltip = null

				$scope.$on "$destroy", ->
					clearPopup()
					clearTooltip()

				if options.popupTemplateUrl
					$http.get(options.popupTemplateUrl).then (response)->
						popupTemplateData = response.data

				if options.tooltipTemplateUrl
					$http.get(options.tooltipTemplateUrl).then (response)->
						tooltipTemplateData = response.data

				removeChildren = (annotation)->
					for i in [annotation.children.length - 1..0] by -1
						a = annotation.children[i]
						removeChildren a
						a.children.splice i, 1

				removeAnnotation = (id, annotations)->
					for a, i in annotations
						removeAnnotation id, a.children

						if a.id is id
							removeChildren a
							annotations.splice i, 1
							return

				createAnnotation = ->
					annotation = new NGAnnotation()
					sel = window.getSelection()

					if sel.isCollapsed
						throw new Error "NG_ANNOTATE_NO_TEXT_SELECTED"

					range = sel.getRangeAt 0

					if range.startContainer isnt range.endContainer
						throw new Error "NG_ANNOTATE_PARTIAL_NODE_SELECTED"

					if range.startContainer.parentNode.nodeName is "SPAN" # Is a child annotation
						parentId = if (attrId = range.startContainer.parentNode.getAttribute("data-annotation-id"))? then parseInt(attrId, 10)
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
							# Doesn't have a prev sibling, alrighty then
							annotation.startIndex = range.startOffset
							annotation.endIndex = range.endOffset
					else
						# Nope
						annotation.startIndex = range.startOffset
						annotation.endIndex = range.endOffset

					annotationParentCollection.push annotation
					clearSelection()
					return annotation

				clearSelection = ->
					if document.selection
						document.selection.empty() # Internet Explorer
					else if window.getSelection and window.getSelection().empty
						window.getSelection().empty() # Chrome
					else if window.getSelection and window.getSelection().removeAllRanges
						window.getSelection().removeAllRanges() # Firefox

				onSelect = (event)->
					if popupTemplateData.length is 0
						return

					try
						annotation = createAnnotation()
						$scope.$apply()
						$span = element.find ".ng-annotate-" + annotation.id
					catch ex
						if $scope.onAnnotateError?
							$scope.onAnnotateError ex

						return

					clearPopup()
					clearTooltip()

					loadAnnotationPopup annotation, $span, true

				onClick = (event)->					
					if popupTemplateData.length is 0
						return

					$target = angular.element event.target
					targetId = if (attrId = $target.attr("data-annotation-id"))? then parseInt(attrId, 10)

					if not targetId?
						return

					if activePopup? and activePopup.scope.$annotation.id is targetId
						clearPopup()
						return
					annotation = getAnnotationById $scope.annotations, targetId

					clearPopup()
					clearTooltip()

					loadAnnotationPopup annotation, $target, false

				onMouseEnter = (event)->
					if tooltipTemplateData.length is 0
						return

					event.stopPropagation()
					$target = angular.element event.target
					targetId = if (attrId = $target.attr("data-annotation-id"))? then parseInt(attrId, 10)

					if activeTooltip? and activeTooltip.scope.$annotation.id is targetId
						activeTooltip.stopDestroy()
						return
					else
						clearTooltip()

					if not targetId?
						return

					annotation = getAnnotationById $scope.annotations, targetId

					# We don't want to show the tooltip if a popup with the annotation is open
					if activePopup?
						return

					tooltip = new NGAnnotateTooltip $rootScope.$new()
					tooltip.scope.$annotation = annotation
					tooltip.$anchor = $target

					tooltip.scope.$reposition = ->
						smartPosition tooltip.$el[0], tooltip.$anchor[0], $scope.popupOffset ? POPUP_OFFSET, 'y'
						return

					activeTooltip = tooltip

					locals = 
						$scope: tooltip.scope
						$template: tooltipTemplateData

					tooltip.$el.html locals.$template
					tooltip.$el.appendTo "body"
					
					if options.tooltipController
						controller = $controller options.tooltipController, locals
						tooltip.$el.data "$ngControllerController", controller
						tooltip.$el.children().data "$ngControllerController", controller

					$compile(tooltip.$el) tooltip.scope
					tooltip.scope.$reposition()
					tooltip.scope.$apply()
					tooltip.show()

				onMouseLeave = (event)->
					event.stopPropagation()

					$target = angular.element event.target
					targetId = if (attrId = $target.attr("data-annotation-id"))? then parseInt(attrId, 10)

					if not targetId?
						return

					clearTooltip()

				loadAnnotationPopup = (annotation, anchor, isNew)->
					popup = new NGAnnotatePopup $rootScope.$new()
					popup.scope.$isNew = isNew
					popup.scope.$annotation = annotation
					popup.scope.$readonly = options.readonly
					popup.$anchor = anchor
					popup.scope.onEditorShow = $scope.onEditorShow
					popup.scope.onEditorHide = $scope.onEditorHide

					popup.scope.$reject = ->
						removeAnnotation annotation.id, $scope.annotations
						
						if $scope.onAnnotateDelete?
							$scope.onAnnotateDelete annotation
						clearPopup()
						return

					popup.scope.$close = ->
						if $scope.onAnnotate?
							$scope.onAnnotate popup.scope.$annotation
						clearPopup()
						return

					popup.scope.$reposition = ->
						smartPosition popup.$el[0], popup.$anchor[0], $scope.popupOffset ? POPUP_OFFSET
						return

					activePopup = popup

					locals = 
						$scope: popup.scope
						$template: popupTemplateData

					popup.$el.html locals.$template
					popup.$el.appendTo "body"
					
					if options.popupController
						controller = $controller options.popupController, locals
						popup.$el.data "$ngControllerController", controller
						popup.$el.children().data "$ngControllerController", controller

					$compile(popup.$el) popup.scope
					popup.scope.$reposition()
					popup.scope.$apply()
					popup.show()

				element.on "mouseenter", "span", onMouseEnter
				element.on "mouseleave", "span", onMouseLeave

				element.on "mouseup", (event)->
					# We need to determine if the user actually selected something
					# or if he just clicked on an annotation
					selection = window.getSelection()
					if !selection.isCollapsed and !options.readonly
						# User has selected something
						onSelect event
					else if selection.isCollapsed and event.target.nodeName is "SPAN"
						onClick event
					else if selection.isCollapsed
						clearTooltip()
						clearPopup()
	}
