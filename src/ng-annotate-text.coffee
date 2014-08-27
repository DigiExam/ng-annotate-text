ngAnnotateText = angular.module "ngAnnotateText", []

annotationIdCounter = 0

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
		text = insertAt text, annotation.startIndex + indexOffset, "<span class=\"ng-annotate-text-annotation ng-annotate-text-" + annotation.id + " ng-annotate-text-type-" + annotation.type + "\" data-annotation-id=\"" + annotation.id + "\">"
	return text

getAnnotationById = (annotations, aId)->
	for a in annotations
		if aId is a.id
			return a
		if a.children.length > 0
			an = getAnnotationById a.children, aId
			if an isnt undefined
				return an

ngAnnotateText.factory "NGAnnotateTextPopup", ->
	(args) ->
		args = angular.extend {
			scope: null,
			callbacks: {},
			template: "<div/>"
			$anchor: null
			preferredAxis: 'x'
			offset: 0
			positionClass: '{{position}}'
		}, args

		angular.extend @, args,
			$el: angular.element args.template

			show: (speed = "fast") ->
				@$el.fadeIn speed
				@reposition()
				if typeof @callbacks.show is "function"
					@callbacks.show @$el

			hide: (speed = "fast")->
				@$el.fadeOut speed
				if typeof @callbacks.hide is "function"
					@callbacks.hide @$el

			isVisible: ->
				return @$el.is ":visible"

			destroy: (cb = angular.noop)->
				scope = @scope
				$el = @$el
				@hide ->
					if typeof cb is "function"
						cb()
					scope.$destroy()
					$el.remove()

			stopDestroy: ->
				@$el.stop(true).show("fast")

			reposition: ->
				targetEl = @$el[0]
				anchorEl = @$anchor[0]

				if not (targetEl or anchorEl)
					return

				pos =
					left: null
					top: null
					target: targetEl.getBoundingClientRect()
					anchor: anchorEl.getBoundingClientRect()
					viewport:
						width: window.innerWidth
						height: window.innerHeight
					scroll:
						top: document.body.scrollTop
						left: document.body.scrollLeft

				if not (pos.target.width > 0 and pos.target.height > 0)
					return

				# Find first axis position

				posX = @getNewPositionOnAxis pos, 'x'
				posY = @getNewPositionOnAxis pos, 'y'

				if @preferredAxis is 'x'
					if posX and typeof posX.pos is 'number'
						pos.left = posX.pos
						pos.edge = posX.edge
					else if posY
						pos.top = posY.pos
						pos.edge = posY.edge
				else
					if posY and typeof posY.pos is 'number'
						pos.top = posY.pos
						pos.edge = posY.edge
					else if posX
						pos.left = posX.pos
						pos.edge = posX.edge

				# Center on second axis

				if pos.left is null and pos.top is null
					# Center on X and Y axes
					pos.left = pos.scroll.left + (pos.viewport.width / 2) - (pos.target.width / 2)
					pos.top = pos.scroll.top + (pos.viewport.height / 2) - (pos.target.height / 2)
				else if pos.left is null
					# Center on X axis
					pos.left = @getNewCenterPositionOnAxis pos, 'x'
				else if pos.top is null
					# Center on Y axis
					pos.top = @getNewCenterPositionOnAxis pos, 'y'

				@$el
					.addClass pos.edge && @positionClass.replace "{{position}}", pos.edge
					.css
						top: Math.round(pos.top) || 0
						left: Math.round(pos.left) || 0

				return

			getNewPositionOnAxis: (pos, axis) ->
				start = {x: 'left', y: 'top'}[axis]
				end = {x: 'right', y: 'bottom'}[axis]
				size = {x: 'width', y: 'height'}[axis]
				if pos.anchor[start] - @offset >= pos.target[size]
					axisPos =
						pos: pos.scroll[start] + pos.anchor[start] - @offset - pos.target[size]
						edge: start
				else if pos.viewport[size] - pos.anchor[end] - @offset >= pos.target[size]
					axisPos =
						pos: pos.scroll[start] + pos.anchor[end] + @offset
						edge: end
				axisPos

			getNewCenterPositionOnAxis: (pos, axis) ->
				start = {x: 'left', y: 'top'}[axis]
				size = {x: 'width', y: 'height'}[axis]
				centerPos = pos.scroll[start] + pos.anchor[start] + (pos.anchor[size] / 2) - (pos.target[size] / 2)
				Math.max(pos.scroll[start] + @offset, Math.min(centerPos, pos.scroll[start] + pos.viewport[size] - pos.target[size] - @offset))

ngAnnotateText.factory "NGAnnotation", ->
	Annotation = (data)->

		angular.extend @,
			id: annotationIdCounter++,
			startIndex: null
			endIndex: null
			data: {points: 0}
			type: ""
			children: []

		if data?
			angular.extend @, data

	return Annotation

ngAnnotateText.directive "ngAnnotateText", ($rootScope, $compile, $http, $q, $controller, $sce, NGAnnotation, NGAnnotateTextPopup)->
	restrict: "E"
	scope:
		text: "="
		annotations: "="
		readonly: "="
		popupController: "="
		popupTemplateUrl: "="
		tooltipController: "="
		tooltipTemplateUrl: "="
		onAnnotate: "="
		onAnnotateDelete: "="
		onAnnotateError: "="
		onPopupShow: "="
		onPopupHide: "="
		popupOffset: "="
	template: "<p ng-bind-html=\"content\"></p>"
	replace: true

	compile: (el, attr) ->
		attr.readonly ?= false
		@postLink

	postLink: ($scope, element, attrs) ->
		POPUP_OFFSET = $scope.popupOffset ? 10

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

		clearPopups = ->
			clearPopup()
			clearTooltip()

		$scope.$on "$destroy", clearPopups
		$scope.$on "ngAnnotateText.clearPopups", clearPopups

		if $scope.popupTemplateUrl
			$http.get($scope.popupTemplateUrl).then (response)->
				popupTemplateData = response.data

		if $scope.tooltipTemplateUrl
			$http.get($scope.tooltipTemplateUrl).then (response)->
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
				throw new Error "NG_ANNOTATE_TEXT_NO_TEXT_SELECTED"

			range = sel.getRangeAt 0

			if range.startContainer isnt range.endContainer
				throw new Error "NG_ANNOTATE_TEXT_PARTIAL_NODE_SELECTED"

			if range.startContainer.parentNode.nodeName is "SPAN" # Is a child annotation
				parentId = if (attrId = range.startContainer.parentNode.getAttribute("data-annotation-id"))? then parseInt(attrId, 10)
				if parentId is undefined
					throw new Error "NG_ANNOTATE_TEXT_ILLEGAL_SELECTION"
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
						throw new Error "NG_ANNOTATE_TEXT_ILLEGAL_SELECTION"

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
				$span = element.find ".ng-annotate-text-" + annotation.id
			catch ex
				if $scope.onAnnotateError?
					$scope.onAnnotateError ex

				return

			clearPopups()

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

			clearPopups()

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

			# We don't want to show the tooltip if a popup with the annotation is open,
			# or if the tooltip has both no comment and points
			if activePopup? or (not annotation.data.comment and not annotation.data.points)
				return

			tooltip = new NGAnnotateTextPopup
				scope: $rootScope.$new()
				template: "<div class='ng-annotate-text-tooltip' />"
				positionClass: "ng-annotate-text-tooltip-docked ng-annotate-text-tooltip-docked-{{position}}"
				$anchor: $target
				preferredAxis: 'y'
				offset: POPUP_OFFSET
			tooltip.scope.$annotation = annotation

			activeTooltip = tooltip

			locals =
				$scope: tooltip.scope
				$template: tooltipTemplateData

			tooltip.$el.html locals.$template
			tooltip.$el.appendTo "body"

			if $scope.tooltipController
				controller = $controller $scope.tooltipController, locals
				tooltip.$el.data "$ngControllerController", controller
				tooltip.$el.children().data "$ngControllerController", controller

			$compile(tooltip.$el) tooltip.scope
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
			popup = new NGAnnotateTextPopup
				scope: $rootScope.$new()
				callbacks:
					show: $scope.onPopupShow
					hide: $scope.onPopupHide
				template: "<div class='ng-annotate-text-popup' />"
				positionClass: "ng-annotate-text-popup-docked ng-annotate-text-popup-docked-{{position}}"
				$anchor: anchor
				offset: POPUP_OFFSET

			popup.scope.$isNew = isNew
			popup.scope.$annotation = annotation
			popup.scope.$readonly = $scope.readonly

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

			activePopup = popup

			locals =
				$scope: popup.scope
				$template: popupTemplateData

			popup.$el.html locals.$template
			popup.$el.appendTo "body"

			if $scope.popupController
				controller = $controller $scope.popupController, locals
				popup.$el.data "$ngControllerController", controller
				popup.$el.children().data "$ngControllerController", controller

			$compile(popup.$el) popup.scope
			popup.scope.$apply()
			popup.show()

		element.on "mouseenter", "span", onMouseEnter
		element.on "mouseleave", "span", onMouseLeave

		element.on "mouseup", (event)->
			# We need to determine if the user actually selected something
			# or if he just clicked on an annotation
			selection = window.getSelection()
			if !selection.isCollapsed and !$scope.readonly
				# User has selected something
				onSelect event
			else if selection.isCollapsed and event.target.nodeName is "SPAN"
				onClick event
			else if selection.isCollapsed
				clearPopups()
