var app = angular.module("app", ["ngAnnotate"]);

app.controller("MainController", function($scope)
{
	$scope.annotate = function($data)
	{
		console.log($data);
	};
});