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

getAnnotationById = (annotations, aId)->
	for a in annotations
		if aId is a.id
			return a
		if a.children.length > 0
			an = getAnnotationById a.children, aId
			if an isnt undefined
				return an

ngAnnotate.factory "NGAnnotatePopup", ->
	NGAnnotatePopup = (scope)->

		angular.extend @,
			scope: scope
			$el: angular.element "<div class=\"ng-annotation-popup\" />"
			$anchor: null

			show: (cb = angular.noop, speed = "fast")->
				@$el.fadeIn speed, cb

			hide: (cb = angular.noop, speed = "fast")->
				@$el.fadeOut speed, cb

			isVisible: ->
				return @$el.is ":visible"

			positionTop: ->
				if not @$anchor?
					throw new Error "NG_ANNOTATE_NO_ANCHOR"

				anchorOffsetTop = @$anchor.offset().top
				anchorHeight = @$anchor.innerHeight()
				popupHeight = @$el.innerHeight()
				@$el.css
					top: anchorOffsetTop + (anchorHeight / 2) - (popupHeight / 2)

			positionLeft: (value)->
				@$el.css
					left: value

			destroy: ->
				scope = @scope
				$el = @$el
				@hide ->
					scope.$destroy()
					$el.remove()

	return NGAnnotatePopup

ngAnnotate.factory "NGAnnotateTooltip", ->
	NGAnnotateTooltip = (scope)->

		angular.extend @,
			scope: scope,
			$el: angular.element "<div class=\"ng-annotation-tooltip\" />"
			$anchor: null

			show: (cb = angular.noop, speed = "fast")->
				@$el.fadeIn speed, cb

			hide: (cb = angular.noop, speed = "fast")->
				@$el.fadeOut speed, cb

			isVisible: ->
				return @$el.is ":visible"

			positionTop: ->
				if not @$anchor?
					throw new Error "NG_ANNOTATE_NO_ANCHOR"

				anchorOffsetTop = @$anchor.offset().top
				anchorHeight = @$anchor.innerHeight()
				tooltipHeight = @$el.innerHeight()
				@$el.css
					top: anchorOffsetTop + (anchorHeight / 2) - (tooltipHeight / 2)

			positionLeft: (value)->
				@$el.css
					left: value

			destroy: ->
				scope = @scope
				$el = @$el
				@hide ->
					scope.$destroy()
					$el.remove()

ngAnnotate.factory "NGAnnotation", ->
	Annotation = (data)->

		angular.extend @,
			id: new Date().getTime(),
			startIndex: null
			endIndex: null
			data: {}
			type: ""
			children: []

		if data?
			angular.extend @, data

	return Annotation

ngAnnotate.directive "ngAnnotate", ($rootScope, $compile, $http, $q, NGAnnotation, NGAnnotatePopup, NGAnnotateTooltip)->
	return {
		restrict: "A"
		scope:
			text: "="
			annotations: "="
			options: "="
			onAnnotate: "="
			onAnnotateDelete: "="
			onAnnotateError: "="
		compile: (tElement, tAttrs, transclude)->

			return ($scope, element, attrs)->
				activePopups = []
				activeTooltips = []


				# Cache the template when we fetch it
				popupTemplateData = ""
				tooltipTemplateData = ""

				onAnnotationsChange = ->
					if not $scope.text? or !$scope.text.length
						return
					t = parseAnnotations $scope.text, $scope.annotations
					tElement.html t

				# Annotation parsing
				$scope.$watch "text", onAnnotationsChange
				$scope.$watch "annotations", onAnnotationsChange, true

				# Setting options
				options =
					popupTemplateUrl: ""
					tooltipTemplateUrl: ""
				options = angular.extend options, $scope.options

				clearPopups = ->
					for p in activePopups
						p.destroy()
					activePopups = []

				clearTooltips = ->
					for i in [activeTooltips.length - 1..0] by -1
						activeTooltips[i].destroy()
						activeTooltips.splice i, 1

				$scope.$on "$destroy", ->
					clearPopups()
					clearTooltips()

				getPopupTemplate = (url)->
					if popupTemplateData.length
						deferred = $q.defer()
						deferred.resolve popupTemplateData
						return deferred.promise
					
					return $http.get(url).then (response)->
						popupTemplateData = response.data
						return response.data

				getTooltipTemplate = (url)->
					if tooltipTemplateData.length
						deferred = $q.defer()
						deferred.resolve tooltipTemplateData
						return deferred.promise

					return $http.get(url).then (response)->
						tooltipTemplateData = response.data
						return response.data

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
					if sel.type isnt "Range"
						throw new Error "NG_ANNOTATE_NO_TEXT_SELECTED"
					range = sel.getRangeAt 0
					if range.startContainer isnt range.endContainer
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
							# Doesn't have a prev sibling, alrighty then
							annotation.startIndex = range.startOffset
							annotation.endIndex = range.endOffset
					else
						# Nope
						annotation.startIndex = range.startOffset
						annotation.endIndex = range.endOffset

					annotationParentCollection.push annotation
					return annotation

				onSelect = (event)->
					try
						annotation = createAnnotation()
						$scope.$apply()
						$span = element.find ".ng-annotation-" + annotation.id
					catch ex
						if $scope.onAnnotateError?
							$scope.onAnnotateError ex

						return

					clearPopups()
					clearTooltips()

					popup = new NGAnnotatePopup $rootScope.$new()
					popup.scope.$isNew = true
					popup.scope.$annotation = annotation
					popup.$anchor = $span

					popup.scope.$reject = ->
						removeAnnotation annotation.id, $scope.annotations
						
						if $scope.onAnnotateDelete?
							$scope.onAnnotateDelete annotation

						clearPopups()
						popup.destroy()

					popup.scope.$close = ->
						if $scope.onAnnotate?
							$scope.onAnnotate popup.scope.$annotation

						clearPopups()
						popup.destroy()

					activePopups.push popup

					getTemplatePromise = getPopupTemplate options.popupTemplateUrl
					getTemplatePromise.then (template)->
						$compile(angular.element(template)) popup.scope, ($content)->
							popup.$el.html $content
							popup.$el.appendTo "body"
							popup.positionTop()
							popup.positionLeft element.offset().left - popup.$el.innerWidth()
							popup.show()

				onClick = (event)->
					$target = angular.element event.target
					targetId = if (attrId = $target.attr("data-annotation-id"))? then parseInt(attrId, 10)

					if not targetId?
						return

					if activePopups.length
						for p in activePopups
							if p.scope? and p.scope.$annotation.id is targetId
								clearPopups()
								return
					clearPopups()
					clearTooltips()

					annotation = getAnnotationById $scope.annotations, targetId
					popup = new NGAnnotatePopup $rootScope.$new()
					popup.scope.$isNew = false
					popup.scope.$annotation = annotation
					popup.$anchor = $target

					popup.scope.$reject = ->
						removeAnnotation targetId, $scope.annotations
						if typeof($scope.onAnnotateDelete) is "function"
							$scope.onAnnotateDelete annotation
						clearPopups()
						popup.destroy()

					popup.scope.$close = ->
						if typeof($scope.onAnnotate) is "function"
							$scope.onAnnotate popup.scope.$annotation
						clearPopups()
						popup.destroy()

					activePopups.push popup
					
					getTemplatePromise = getPopupTemplate options.popupTemplateUrl
					getTemplatePromise.then (template)->
						$compile(angular.element(template)) popup.scope, ($content)->
							popup.$el.html $content
							popup.$el.appendTo "body"
							popup.positionTop()
							popup.positionLeft element.offset().left - popup.$el.innerWidth()
							popup.show()

				onMouseEnter = (event)->
					event.stopPropagation()
					$target = angular.element event.target
					targetId = if (attrId = $target.attr("data-annotation-id"))? then parseInt(attrId, 10)

					if not targetId?
						return

					annotation = getAnnotationById $scope.annotations, targetId

					# We don't want to show the tooltip if a popup with the annotation is open
					if activePopups.length
						return

					tooltip = new NGAnnotateTooltip $rootScope.$new()
					tooltip.scope.$annotation = annotation
					tooltip.$anchor = $target
					activeTooltips.push tooltip

					getTemplatePromise = getTooltipTemplate options.tooltipTemplateUrl
					getTemplatePromise.then (template)->
						$compile(angular.element(template)) tooltip.scope, ($content)->
							tooltip.$el.html $content
							tooltip.$el.appendTo "body"
							tooltip.positionTop()
							tooltip.positionLeft element.offset().left - tooltip.$el.innerWidth()
							tooltip.show()

				onMouseLeave = (event)->
					event.stopPropagation()
					$target = angular.element event.target
					targetId = if (attrId = $target.attr("data-annotation-id"))? then parseInt(attrId, 10)

					if not targetId?
						return

					clearTooltips()

				element.on "mouseover", "span", onMouseEnter
				element.on "mouseleave", "span", onMouseLeave

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