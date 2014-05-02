var ngAnnotate = angular.module("ngAnnotate", []);

ngAnnotate.directive("ngAnnotate", function($parse, $timeout)
{
	return {
		restrict: "A",
		link: function($scope, element, attrs)
		{
			var fn = $parse(attrs["ngAnnotate"]);
			element.on("mouseup", function(event)
			{
				var data = { data: "woho" };
				event.preventDefault();
				// Find selected text
				// Wrap span around it
				// Get offset of span
				// Return data
				$timeout(function() { fn($scope, { $data: data, $event: event }); });
			});
		}
	}
});