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

ngAnnotate.factory "NGAnnotatePopupStack", ->
	NGAnnotatePopupStack = ->
		stack = []
		angular.extend @,
			push: (key, item)->
				stack.push
					key: key,
					value: item

			moveToTop: (key)->
				for p, i in stack
					if p.key is key
						item = stack.splice(i, 1)[0]
						break
				if item?
					stack.push item

			top: ->
				item = stack[stack.length - 1]
				if item?
					return item.value

			keys: ->
				keys = []
				for p in stack
					keys.push p.key
				return keys

			get: (key)->
				for p in stack
					if p.key is key
						return p.value

			remove: (key)->
				for i in [stack.length - 1..0] by -1
					item = stack[i]
					if item.key is key
						item.value.destroy()
						return stack.splice(i, 1)[0]

			clear: ->
				for i in [stack.length - 1..0] by -1
					item = stack[i]
					item.value.destroy()
					stack.splice i, 1
				stack = []
				return

			length: ->
				return stack.length

	return NGAnnotatePopupStack

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
					throw new Error "NG_ANNOTATE_NO_ANCHOR_ON_POPUP"

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

ngAnnotate.directive "ngAnnotate", ($rootScope, $compile, $http, $q, NGAnnotation, NGAnnotatePopup, NGAnnotatePopupStack)->
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

				$scope.$on "$destroy", ->
					popupStack.clear()

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
					tooltipTemplateUrl: ""
				options = angular.extend options, $scope.options

				getTemplate = (url)->
					if templateData.length
						deferred = $q.defer()
						deferred.resolve templateData
						return deferred.promise
					
					return $http.get(url).then (response)->
						templateData = response.data
						return response.data

				removeChildren = (annotation)->
					for i in [annotation.children.length - 1..0] by -1
						a = annotation.children[i]
						removeChildren a
						key = "ng-annotation-" + a.id
						popup = popupStack.remove key
						a.children.splice i, 1

				removeAnnotation = (id, annotations)->
					for a, i in annotations
						if a.id is id
							removeChildren a
							key = "ng-annotation-" + a.id
							popupStack.remove key
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
						$scope.onAnnotateError ex
						return

					key = "ng-annotation-" + annotation.id
					topStackPopup = popupStack.top()
					if topStackPopup?
						topStackPopup.hide()

					popup = popupStack.get key
					if popup?
						popup.show()
						popupStack.moveToTop key
						return

					popup = new NGAnnotatePopup $rootScope.$new()
					popup.scope.$isNew = true
					popup.scope.$annotation = annotation
					popup.$anchor = $span

					popup.scope.$reject = ->
						removeAnnotation annotation.id, $scope.annotations
						popupStack.remove key
						popup.destroy()

					popup.scope.$close = ->
						$scope.onAnnotate popup.scope.$annotation
						popupStack.remove key
						popup.destroy()

					popupStack.push key, popup

					getTemplatePromise = getTemplate options.popupTemplateUrl
					getTemplatePromise.then (template)->
						$compile(angular.element(template)) popup.scope, ($content)->
							popup.$el.html $content
							popup.$el.appendTo "body"
							popup.positionTop()
							popup.positionLeft element.offset().left - 320
							popup.show()

				onClick = (event)->
					$target = angular.element event.target
					targetId = if (attrId = $target.attr("data-annotation-id"))? then parseInt(attrId, 10)

					if not targetId?
						return

					key = "ng-annotation-" + targetId
					topStackPopup = popupStack.top()
					if topStackPopup?
						if topStackPopup.scope.$annotation.id is targetId
							if topStackPopup.isVisible()
								topStackPopup.hide()
							else
								topStackPopup.show()
							return

						topStackPopup.hide()

					popup = popupStack.get key
					if popup?
						popup.show()
						popup.scope.$isNew = false
						popupStack.moveToTop key
						return

					popup = new NGAnnotatePopup $rootScope.$new()
					popup.scope.$isNew = false
					popup.scope.$annotation = getAnnotationById $scope.annotations, targetId
					popup.$anchor = $target

					popup.scope.$reject = ->
						removeAnnotation targetId, $scope.annotations
						popupStack.remove key
						popup.destroy()

					popup.scope.$close = ->
						$scope.onAnnotate popup.scope.$annotation
						popupStack.remove key
						popup.destroy()

					popupStack.push key, popup
					
					getTemplatePromise = getTemplate options.popupTemplateUrl
					getTemplatePromise.then (template)->
						$compile(angular.element(template)) popup.scope, ($content)->
							popup.$el.html $content
							popup.$el.appendTo "body"
							popup.positionTop()
							popup.positionLeft element.offset().left - 320
							popup.show()

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
					else
						topStackPopup = popupStack.top()
						if topStackPopup?
							topStackPopup.hide()
	}