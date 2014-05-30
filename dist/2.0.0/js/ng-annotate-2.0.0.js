(function() {
  var getAnnotationById, insertAt, ngAnnotate, parseAnnotations, sortAnnotationsByEndIndex;

  ngAnnotate = angular.module("ngAnnotate", []);

  insertAt = function(text, index, string) {
    return text.substr(0, index) + string + text.substr(index);
  };

  sortAnnotationsByEndIndex = function(annotations) {
    return annotations.sort(function(a, b) {
      if (a.endIndex < b.endIndex) {
        return -1;
      } else if (a.endIndex > b.endIndex) {
        return 1;
      }
      return 0;
    });
  };

  parseAnnotations = function(text, annotations, indexOffset) {
    var annotation, i, _i, _ref;
    if (annotations == null) {
      annotations = [];
    }
    if (indexOffset == null) {
      indexOffset = 0;
    }
    if (annotations.length === 0) {
      return text;
    }
    annotations = sortAnnotationsByEndIndex(annotations);
    for (i = _i = _ref = annotations.length - 1; _i >= 0; i = _i += -1) {
      annotation = annotations[i];
      text = insertAt(text, annotation.endIndex + indexOffset, "</span>");
      if (annotation.children.length) {
        text = parseAnnotations(text, annotation.children, annotation.startIndex + indexOffset);
      }
      text = insertAt(text, annotation.startIndex + indexOffset, "<span class=\"ng-annotation ng-annotation-" + annotation.id + " " + annotation.type + "\" data-annotation-id=\"" + annotation.id + "\">");
    }
    return text;
  };

  getAnnotationById = function(annotations, aId) {
    var a, an, _i, _len;
    for (_i = 0, _len = annotations.length; _i < _len; _i++) {
      a = annotations[_i];
      if (aId === a.id) {
        return a;
      }
      if (a.children.length > 0) {
        an = getAnnotationById(a.children, aId);
        if (an !== void 0) {
          return an;
        }
      }
    }
  };

  ngAnnotate.factory("NGAnnotatePopup", function() {
    var NGAnnotatePopup;
    NGAnnotatePopup = function(scope) {
      return angular.extend(this, {
        scope: scope,
        $el: angular.element("<div class=\"ng-annotation-popup\" />"),
        $anchor: null,
        show: function(cb, speed) {
          if (cb == null) {
            cb = angular.noop;
          }
          if (speed == null) {
            speed = "fast";
          }
          return this.$el.fadeIn(speed, cb);
        },
        hide: function(cb, speed) {
          if (cb == null) {
            cb = angular.noop;
          }
          if (speed == null) {
            speed = "fast";
          }
          return this.$el.fadeOut(speed, cb);
        },
        isVisible: function() {
          return this.$el.is(":visible");
        },
        positionTop: function() {
          var anchorHeight, anchorOffsetTop, popupHeight;
          if (this.$anchor == null) {
            throw new Error("NG_ANNOTATE_NO_ANCHOR");
          }
          anchorOffsetTop = this.$anchor.offset().top;
          anchorHeight = this.$anchor.innerHeight();
          popupHeight = this.$el.innerHeight();
          return this.$el.css({
            top: anchorOffsetTop + (anchorHeight / 2) - (popupHeight / 2)
          });
        },
        positionLeft: function(value) {
          return this.$el.css({
            left: value
          });
        },
        destroy: function() {
          var $el;
          scope = this.scope;
          $el = this.$el;
          return this.hide(function() {
            scope.$destroy();
            return $el.remove();
          });
        }
      });
    };
    return NGAnnotatePopup;
  });

  ngAnnotate.factory("NGAnnotateTooltip", function() {
    var NGAnnotateTooltip;
    return NGAnnotateTooltip = function(scope) {
      return angular.extend(this, {
        scope: scope,
        $el: angular.element("<div class=\"ng-annotation-tooltip\" />"),
        $anchor: null,
        show: function(cb, speed) {
          if (cb == null) {
            cb = angular.noop;
          }
          if (speed == null) {
            speed = "fast";
          }
          return this.$el.fadeIn(speed, cb);
        },
        hide: function(cb, speed) {
          if (cb == null) {
            cb = angular.noop;
          }
          if (speed == null) {
            speed = "fast";
          }
          return this.$el.fadeOut(speed, cb);
        },
        isVisible: function() {
          return this.$el.is(":visible");
        },
        positionTop: function() {
          var anchorHeight, anchorOffsetTop, tooltipHeight;
          if (this.$anchor == null) {
            throw new Error("NG_ANNOTATE_NO_ANCHOR");
          }
          anchorOffsetTop = this.$anchor.offset().top;
          anchorHeight = this.$anchor.innerHeight();
          tooltipHeight = this.$el.innerHeight();
          return this.$el.css({
            top: anchorOffsetTop + (anchorHeight / 2) - (tooltipHeight / 2)
          });
        },
        positionLeft: function(value) {
          return this.$el.css({
            left: value
          });
        },
        destroy: function() {
          var $el;
          scope = this.scope;
          $el = this.$el;
          return this.hide(function() {
            scope.$destroy();
            return $el.remove();
          });
        }
      });
    };
  });

  ngAnnotate.factory("NGAnnotation", function() {
    var Annotation;
    Annotation = function(data) {
      angular.extend(this, {
        id: new Date().getTime(),
        startIndex: null,
        endIndex: null,
        data: {},
        type: "",
        children: []
      });
      if (data != null) {
        return angular.extend(this, data);
      }
    };
    return Annotation;
  });

  ngAnnotate.directive("ngAnnotate", function($rootScope, $compile, $http, $q, $controller, NGAnnotation, NGAnnotatePopup, NGAnnotateTooltip) {
    return {
      restrict: "A",
      scope: {
        text: "=",
        annotations: "=",
        options: "=",
        onAnnotate: "=",
        onAnnotateDelete: "=",
        onAnnotateError: "="
      },
      compile: function(tElement, tAttrs, transclude) {
        return function($scope, element, attrs) {
          var activePopups, activeTooltips, clearPopups, clearTooltips, createAnnotation, loadAnnotationPopup, onAnnotationsChange, onClick, onMouseEnter, onMouseLeave, onSelect, options, popupTemplateData, removeAnnotation, removeChildren, tooltipTemplateData;
          activePopups = [];
          activeTooltips = [];
          popupTemplateData = "";
          tooltipTemplateData = "";
          onAnnotationsChange = function() {
            var t;
            if (($scope.text == null) || !$scope.text.length) {
              return;
            }
            t = parseAnnotations($scope.text, $scope.annotations);
            return tElement.html(t);
          };
          $scope.$watch("text", onAnnotationsChange);
          $scope.$watch("annotations", onAnnotationsChange, true);
          options = {
            popupController: "",
            popupTemplateUrl: "",
            tooltipController: "",
            tooltipTemplateUrl: ""
          };
          options = angular.extend(options, $scope.options);
          clearPopups = function() {
            var p, _i, _len;
            for (_i = 0, _len = activePopups.length; _i < _len; _i++) {
              p = activePopups[_i];
              p.destroy();
            }
            return activePopups = [];
          };
          clearTooltips = function() {
            var i, _i, _ref, _results;
            _results = [];
            for (i = _i = _ref = activeTooltips.length - 1; _i >= 0; i = _i += -1) {
              activeTooltips[i].destroy();
              _results.push(activeTooltips.splice(i, 1));
            }
            return _results;
          };
          $scope.$on("$destroy", function() {
            clearPopups();
            return clearTooltips();
          });
          $http.get(options.popupTemplateUrl).then(function(response) {
            return popupTemplateData = response.data;
          });
          $http.get(options.tooltipTemplateUrl).then(function(response) {
            return tooltipTemplateData = response.data;
          });
          removeChildren = function(annotation) {
            var a, i, _i, _ref, _results;
            _results = [];
            for (i = _i = _ref = annotation.children.length - 1; _i >= 0; i = _i += -1) {
              a = annotation.children[i];
              removeChildren(a);
              _results.push(a.children.splice(i, 1));
            }
            return _results;
          };
          removeAnnotation = function(id, annotations) {
            var a, i, _i, _len;
            for (i = _i = 0, _len = annotations.length; _i < _len; i = ++_i) {
              a = annotations[i];
              removeAnnotation(id, a.children);
              if (a.id === id) {
                removeChildren(a);
                annotations.splice(i, 1);
                return;
              }
            }
          };
          createAnnotation = function() {
            var annotation, annotationParentCollection, attrId, parentAnnotation, parentId, prevAnnotation, prevSiblingId, prevSiblingSpan, range, sel;
            annotation = new NGAnnotation();
            sel = window.getSelection();
            if (sel.type !== "Range") {
              throw new Error("NG_ANNOTATE_NO_TEXT_SELECTED");
            }
            range = sel.getRangeAt(0);
            if (range.startContainer !== range.endContainer) {
              throw new Error("NG_ANNOTATE_PARTIAL_NODE_SELECTED");
            }
            if (range.startContainer.parentElement.nodeName === "SPAN") {
              parentId = (attrId = range.startContainer.parentElement.getAttribute("data-annotation-id")) != null ? parseInt(attrId, 10) : void 0;
              if (parentId === void 0) {
                throw new Error("NG_ANNOTATE_ILLEGAL_SELECTION");
              }
              parentAnnotation = getAnnotationById($scope.annotations, parentId);
              annotationParentCollection = parentAnnotation.children;
            } else {
              annotationParentCollection = $scope.annotations;
            }
            if (annotationParentCollection.length) {
              prevSiblingSpan = range.startContainer.previousSibling;
              if (prevSiblingSpan != null) {
                prevSiblingId = (attrId = prevSiblingSpan.getAttribute("data-annotation-id")) != null ? parseInt(attrId, 10) : void 0;
                if (prevSiblingId == null) {
                  throw new Error("NG_ANNOTATE_ILLEGAL_SELECTION");
                }
                prevAnnotation = getAnnotationById($scope.annotations, prevSiblingId);
                annotation.startIndex = prevAnnotation.endIndex + range.startOffset;
                annotation.endIndex = prevAnnotation.endIndex + range.endOffset;
              } else {
                annotation.startIndex = range.startOffset;
                annotation.endIndex = range.endOffset;
              }
            } else {
              annotation.startIndex = range.startOffset;
              annotation.endIndex = range.endOffset;
            }
            annotationParentCollection.push(annotation);
            return annotation;
          };
          onSelect = function(event) {
            var $span, annotation, ex;
            if (popupTemplateData.length === 0) {
              return;
            }
            try {
              annotation = createAnnotation();
              $scope.$apply();
              $span = element.find(".ng-annotation-" + annotation.id);
            } catch (_error) {
              ex = _error;
              if ($scope.onAnnotateError != null) {
                $scope.onAnnotateError(ex);
              }
              return;
            }
            clearPopups();
            clearTooltips();
            return loadAnnotationPopup(annotation, $span, true);
          };
          onClick = function(event) {
            var $target, annotation, attrId, p, targetId, _i, _len;
            if (popupTemplateData.length === 0) {
              return;
            }
            $target = angular.element(event.target);
            targetId = (attrId = $target.attr("data-annotation-id")) != null ? parseInt(attrId, 10) : void 0;
            if (targetId == null) {
              return;
            }
            if (activePopups.length) {
              for (_i = 0, _len = activePopups.length; _i < _len; _i++) {
                p = activePopups[_i];
                if ((p.scope != null) && p.scope.$annotation.id === targetId) {
                  clearPopups();
                  return;
                }
              }
            }
            annotation = getAnnotationById($scope.annotations, targetId);
            clearPopups();
            clearTooltips();
            return loadAnnotationPopup(annotation, $target, false);
          };
          onMouseEnter = function(event) {
            var $target, annotation, attrId, controller, locals, targetId, tooltip;
            if (tooltipTemplateData.length === 0) {
              return;
            }
            event.stopPropagation();
            $target = angular.element(event.target);
            targetId = (attrId = $target.attr("data-annotation-id")) != null ? parseInt(attrId, 10) : void 0;
            clearTooltips();
            if (targetId == null) {
              return;
            }
            annotation = getAnnotationById($scope.annotations, targetId);
            if (activePopups.length) {
              return;
            }
            tooltip = new NGAnnotateTooltip($rootScope.$new());
            tooltip.scope.$annotation = annotation;
            tooltip.$anchor = $target;
            tooltip.scope.$reposition = function() {
              tooltip.positionTop();
              tooltip.positionLeft(element.offset().left - tooltip.$el.innerWidth());
            };
            activeTooltips.push(tooltip);
            locals = {
              $scope: tooltip.scope,
              $template: tooltipTemplateData
            };
            tooltip.$el.html(locals.$template);
            tooltip.$el.appendTo("body");
            if (options.tooltipController) {
              controller = $controller(options.tooltipController, locals);
              tooltip.$el.data("$ngControllerController", controller);
              tooltip.$el.children().data("$ngControllerController", controller);
            }
            $compile(tooltip.$el)(tooltip.scope);
            tooltip.positionTop();
            tooltip.positionLeft(element.offset().left - tooltip.$el.innerWidth());
            tooltip.scope.$apply();
            return tooltip.show();
          };
          onMouseLeave = function(event) {
            var $target, attrId, targetId;
            event.stopPropagation();
            $target = angular.element(event.target);
            targetId = (attrId = $target.attr("data-annotation-id")) != null ? parseInt(attrId, 10) : void 0;
            if (targetId == null) {
              return;
            }
            return clearTooltips();
          };
          loadAnnotationPopup = function(annotation, anchor, isNew) {
            var controller, locals, popup;
            popup = new NGAnnotatePopup($rootScope.$new());
            popup.scope.$isNew = isNew;
            popup.scope.$annotation = annotation;
            popup.$anchor = anchor;
            popup.scope.$reject = function() {
              removeAnnotation(annotation.id, $scope.annotations);
              if ($scope.onAnnotateDelete != null) {
                $scope.onAnnotateDelete(annotation);
              }
              clearPopups();
              popup.destroy();
            };
            popup.scope.$close = function() {
              if ($scope.onAnnotate != null) {
                $scope.onAnnotate(popup.scope.$annotation);
              }
              clearPopups();
              popup.destroy();
            };
            popup.scope.$reposition = function() {
              popup.positionTop();
              popup.positionLeft(element.offset().left - popup.$el.innerWidth());
            };
            activePopups.push(popup);
            locals = {
              $scope: popup.scope,
              $template: popupTemplateData
            };
            popup.$el.html(locals.$template);
            popup.$el.appendTo("body");
            if (options.popupController) {
              controller = $controller(options.popupController, locals);
              popup.$el.data("$ngControllerController", controller);
              popup.$el.children().data("$ngControllerController", controller);
            }
            $compile(popup.$el)(popup.scope);
            popup.positionTop();
            popup.positionLeft(element.offset().left - popup.$el.innerWidth());
            popup.scope.$apply();
            return popup.show();
          };
          element.on("mouseover", "span", onMouseEnter);
          element.on("mouseleave", "span", onMouseLeave);
          return element.on("mouseup", function(event) {
            var selection;
            selection = window.getSelection();
            if (selection.type === "Range") {
              return onSelect(event);
            } else if (selection.type === "Caret" && event.target.nodeName === "SPAN") {
              return onClick(event);
            } else if (selection.type === "Caret") {
              clearTooltips();
              return clearPopups();
            }
          });
        };
      }
    };
  });

}).call(this);
