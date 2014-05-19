(function() {
  var createAnnotationPopup, generateId, getSel, ngAnnotate, parseAnnotations, removeAnnotation, surroundSelection;

  ngAnnotate = angular.module("ngAnnotate", []);

  parseAnnotations = function(text, annotations) {
    var a, i, _i, _ref;
    annotations.sort(function(a, b) {
      if (a.endIndex < b.endIndex) {
        return -1;
      } else if (a.endIndex > b.endIndex) {
        return 1;
      }
      return 0;
    });
    for (i = _i = _ref = annotations.length - 1; _i >= 0; i = _i += -1) {
      a = annotations[i];
    }
    return text;
  };

  createAnnotationPopup = function(id, fields) {
    var $acceptButton, $closeButton, $el, $field, $label, field, _i, _len, _ref;
    $el = $("<div class=\"ng-annotation-popup ng-annotation-popup-" + id + "\" />");
    for (_i = 0, _len = fields.length; _i < _len; _i++) {
      field = fields[_i];
      $label = $("<label>" + field.label + "</label>");
      if (field.type === "textarea") {
        $field = $("<textarea />", {
          "class": field.classes,
          name: field.name,
          "ng-model": "annotation." + field.name
        });
      } else if ((_ref = field.type) === "number" || _ref === "text" || _ref === "date" || _ref === "password") {
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
  };

  removeAnnotation = function($element) {
    return $element.unwrap();
  };

  generateId = function() {
    return Math.floor(Math.random() * 100000);
  };

  getSel = function() {
    var sel;
    sel = window.getSelection();
    if (sel.type !== "Range") {
      throw new Error("NG_ANNOTATE_NO_TEXT_SELECTED");
    }
    return sel;
  };

  surroundSelection = function(node) {
    var ex, range, sel;
    sel = getSel();
    range = sel.getRangeAt(0);
    try {
      return range.surroundContents(node);
    } catch (_error) {
      ex = _error;
      if (ex.name === "InvalidStateError") {
        throw new Error("NG_ANNOTATE_PARTIAL_NODE_SELECTED");
      }
      throw ex;
    }
  };

  ngAnnotate.directive("ngAnnotate", function($parse, $rootScope, $compile, $timeout) {
    return {
      restrict: "A",
      link: function($scope, element, attrs) {
        var annotations, onAnnotate, onAnnotateError, options;
        options = {
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
        annotations = [];
        options = angular.extend(options, $parse(attrs["ngAnnotate"])($scope));
        onAnnotate = $parse(attrs["ngAnnotateOnAnnotation"]);
        onAnnotateError = $parse(attrs["ngAnnotateOnError"]);
        element.on("mousedown", function() {
          var containedToElement, mouseDown;
          return mouseDown = containedToElement = true;
        });
        element.on("mouseleave", function() {
          var containedToElement;
          if (mouseDown) {
            return containedToElement = false;
          }
        });
        element.on("mouseenter", function() {
          var containedToElement;
          if (mouseDown) {
            return containedToElement = true;
          }
        });
        return element.on("mouseup", function(event) {
          var $element, $popup, annotationId, ex, field, height, mouseDown, offset, popupScope, width, _i, _len, _ref;
          if (!containedToElement) {
            return;
          }
          mouseDown = false;
          event.preventDefault();
          annotationId = generateId();
          popupScope = $rootScope.$new();
          popupScope.annotation = {};
          _ref = options.fields;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            field = _ref[_i];
            popupScope.annotation[field.name] = field.defaultValue;
          }
          $element = $("<span />", {
            "class": "ng-annotation ng-annotation-" + annotationId
          });
          try {
            surroundSelection($element.get(0));
          } catch (_error) {
            ex = _error;
            $timeout(function() {
              return onAnnotateError($scope, {
                $ex: ex
              });
            });
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
          return $compile($popup.get(0))(popupScope, function($el, scope) {
            $el.appendTo("body");
            $el.fadeIn("slow");
            $el.find(".ng-annotate-accept").on("click", function(event) {
              event.preventDefault();
              return $timeout(function() {
                return onAnnotate($scope, {
                  $annotation: scope.annotation
                });
              });
            });
            return $el.find(".ng-annotate-close").on("click", function(event) {
              event.preventDefault();
              removeAnnotation($element);
              $el.find("button").off("click");
              return $el.fadeOut("slow", function() {
                return scope.$destroy();
              });
            });
          });
        });
      }
    };
  });

}).call(this);
