var ngAnnotate = angular.module("ngAnnotate", []);

function createAnnotationPopup(id, fields)
{
	var $el = $("<div class=\"ng-annotation-popup ng-annotation-popup-" + id + "\" />");
	var $field, field, $label;
	for(var i = 0; i < fields.length; ++i)
	{
		field = fields[i];
		$label = $("<label>" + field.label + "</label>");
		if(field.type == "textarea")
		{
			$field = $("<textarea />", {
				"class": field.classes,
				name: field.name,
				"ng-model": "annotation." + field.name
			});
		}
		else if(field.type == "number" || field.type == "text" || field.type == "date" || field.type == "password")
		{
			$field = $("<input />", {
				type: field.type,
				"class": field.classes,
				name: field.name,
				"ng-model": "annotation." + field.name
			});
		}
		
		$el.append($label);
		$el.append($field);
	}
	$acceptButton = $("<button>Accept</button>").addClass("ng-annotate-accept");
	$closeButton = $("<button>Close</button>").addClass("ng-annotate-close");
	$el.append([$acceptButton, $closeButton]);
	return $el;
}

function removeAnnotation($element)
{
	$element.unwrap();
}

function generateId()
{
	return Math.floor(Math.random() * 100000);
}

function getSel()
{
	var sel = window.getSelection();
	if (sel.type !== "Range")
		throw new Error("NG_ANNOTATE_NO_TEXT_SELECTED");
	return sel;
}

function surroundSelection(node)
{
	var sel = getSel();
	var range = sel.getRangeAt(0);
	try
	{
		range.surroundContents(node);
	}
	catch(ex)
	{
		if(ex.name == "InvalidStateError")
			throw new Error("NG_ANNOTATE_PARTIAL_NODE_SELECTED");
		throw ex;
	}
}

ngAnnotate.directive("ngAnnotate", function($parse, $rootScope, $compile, $timeout)
{
	return {
		restrict: "A",
		link: function($scope, element, attrs)
		{
			var options = {
				annotations: "annotations",
				fields: [
					{
						name: "comment",
						label: "Comment",
						classes: "ng-annotation-comment",
						type: "textarea",
						defaultValue: "\"\""
					}
				]
			};
			var annotations = [];
			options = angular.extend(options, $parse(attrs["ngAnnotate"])($scope));
			var onAnnotate = $parse(attrs["ngAnnotateOnAnnotation"]);
			var onAnnotateError = $parse(attrs["ngAnnotateOnError"]);

			var containedToElement;
			var mouseDown;

			element.on("mousedown", function() { mouseDown = true; containedToElement = true; });
			element.on("mouseleave", function() { if(mouseDown) containedToElement = false; });
			element.on("mouseenter", function() { if(mouseDown) containedToElement = true; });

			element.on("mouseup", function(event)
			{
				if(!containedToElement)
					return;
				mouseDown = false;

				var annotationId, $element, width, height, offset;

				event.preventDefault();

				// Generate a random ID to assign this annotation
				annotationId = generateId();

				// Create and fill the annotationpopups model with data specified by user
				popupScope = $rootScope.$new();
				popupScope.annotation = {};
				for(var i = 0; i < options.fields.length; ++i)
				{
					field = options.fields[i]
					popupScope[field.name] = field.defaultValue
				}

				$element = $("<span />", {
					"class": "ng-annotation ng-annotation-" + annotationId
				});

				try
				{
					surroundSelection($element.get(0));
				}
				catch(ex)
				{
					$timeout(function() { onAnnotateError($scope, { $ex: ex }) });
					return;
				}

				offset = $element.offset();
				width = $element.innerWidth();
				height = $element.innerHeight();

				$popup = createAnnotationPopup(annotationId, options.fields);
				$popup.css({
					left: element.offset().left - 320,
					top: offset.top - (height / 2) - ($popup.innerHeight() / 2)
				});

				$compile($popup.get(0))(popupScope, function($el, scope)
				{
					$el.appendTo("body");
					$el.fadeIn("slow");

					$el.find(".ng-annotate-accept").on("click", function(event)
					{
						event.preventDefault();
						$timeout(function() { onAnnotate($scope, { $annotation: scope.annotation }) });
					});

					$el.find(".ng-annotate-close").on("click", function(event)
					{
						event.preventDefault();
						removeAnnotation($element);
						$el.find("button").off("click");
						$el.fadeOut("slow", function()
						{
							scope.$destroy();
							//$el.remove();
						});
					});
				});
			});
		}
	}
});