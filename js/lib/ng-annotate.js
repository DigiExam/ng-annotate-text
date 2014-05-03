var ngAnnotate = angular.module("ngAnnotate", []);

function createAnnotationPopup(id)
{
	var $el = $("<div class=\"ng-annotation-popup ng-annotation-popup-" + id + "\" />");
	$el.appendTo("body");
	return $el;
}

ngAnnotate.directive("ngAnnotate", function($parse, $timeout, $q)
{
	return {
		restrict: "A",
		link: function($scope, element, attrs)
		{
			rangy.init();
			var fn = $parse(attrs["ngAnnotate"]);
			var containedToElement;
			var mouseDown = false;

			element.on("mousedown", function() { mouseDown = true; containedToElement = true; });
			element.on("mouseleave", function() { containedToElement = false; });
			element.on("mouseenter", function() { if(mouseDown) { containedToElement = true; } });

			element.on("mouseup", function(event)
			{
				if(!containedToElement)
					return;
				mouseDown = false;

				var annotationId, cssApplier, highlightElement, width, height, offset;

				event.preventDefault();

				annotationId = Math.floor(Math.random() * 100000);

				cssApplier = rangy.createCssClassApplier("ng-annotation-" + annotationId, { normalize: true });
				cssApplier.applyToSelection();

				highlightElement = element.find(".ng-annotation-" + annotationId);
				offset = highlightElement.offset();
				width = highlightElement.innerWidth();
				height = highlightElement.innerHeight();

				cssApplier.undoToSelection();

				$popup = createAnnotationPopup(annotationId);
				$popup.css({
					left: element.offset().left - 320,
					top: offset.top + 50 - (height / 2)
				})

				/*
				deferred.promise.then(function()
				{
					$popup.remove();
					cssApplier.applyToSelection();
					element.find(".ng-annotation-" + annotationId).addClass("ng-annotation");
				}, function()
				{
					$popup.remove();
					cssApplier.undoToSelection();
				});*/

				//$timeout(function() { fn($scope, { $data: data, $deferred: deferred, $event: event }); });
			});
		}
	}
});