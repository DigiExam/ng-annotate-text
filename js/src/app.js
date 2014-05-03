var app = angular.module("app", ["ngAnnotate"]);

app.controller("MainController", function($scope, $timeout)
{

	timeoutPromise = 0;

	$scope.annotate = function($data, $deferred, $event)
	{
		$timeout.cancel(timeoutPromise);

		timeoutPromise = $timeout(function()
		{
			//$deferred.resolve();
			//$scope.showAnnotationPopup = false;
		}, 10000);
		console.log($data);
	};
});