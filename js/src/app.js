var app = angular.module("app", ["ngAnnotate"]);

app.controller("MainController", function($scope)
{
	$scope.annotations = [];
	$scope.options = {
		annotations: $scope.annotations,
		fields: [
			{
				name: "comment",
				label: "Comment",
				classes: "ng-annotation-comment",
				type: "textarea",
				placeholder: "Comment",
				defaultValue: "\"\""
			},
			{
				name: "points",
				label: "Points",
				classes: "annotation-points",
				type: "number",
				defaultValue: 0
			}
		]
	};

	$scope.onAnnotate = function($annotation)
	{
		console.log($annotation);
	};

	$scope.onAnnotateError = function($ex)
	{
		if($ex.message == "NG_ANNOTATE_PARTIAL_NODE_SELECTED")
			alert("You can not partially select an annotation.")
	}
});