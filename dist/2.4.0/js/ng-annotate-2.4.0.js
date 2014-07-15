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
      text = insertAt(text, annotation.startIndex + indexOffset, "<span class=\"ng-annotation ng-annotation-" + annotation.id + " ng-annotation-type-" + annotation.type + "\" data-annotation-id=\"" + annotation.id + "\">");
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
        destroy: function(cb) {
          var $el;
          if (cb == null) {
            cb = angular.noop;
          }
          scope = this.scope;
          $el = this.$el;
          return this.hide(function() {
            cb();
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
        destroy: function(cb) {
          var $el;
          if (cb == null) {
            cb = angular.noop;
          }
          scope = this.scope;
          $el = this.$el;
          return this.hide(function() {
            cb();
            scope.$destroy();
            return $el.remove();
          });
        },
        stopDestroy: function() {
          return this.$el.stop(true).show("fast");
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

  ngAnnotate.directive("ngAnnotate", function($rootScope, $compile, $http, $q, $controller, $sce, NGAnnotation, NGAnnotatePopup, NGAnnotateTooltip) {
    return {
      restrict: "E",
      scope: {
        text: "=",
        annotations: "=",
        options: "=",
        onAnnotate: "=",
        onAnnotateDelete: "=",
        onAnnotateError: "="
      },
      template: "<p ng-bind-html=\"content\"></p>",
      replace: true,
      compile: function(tElement, tAttrs, transclude) {
        var LEFT_MARGIN;
        LEFT_MARGIN = -10;
        return function($scope, element, attrs) {
          var activePopup, activeTooltip, clearPopup, clearSelection, clearTooltip, createAnnotation, loadAnnotationPopup, onAnnotationsChange, onClick, onMouseEnter, onMouseLeave, onSelect, options, popupTemplateData, removeAnnotation, removeChildren, tooltipTemplateData;
          activePopup = null;
          activeTooltip = null;
          popupTemplateData = "";
          tooltipTemplateData = "";
          onAnnotationsChange = function() {
            var t;
            if (($scope.text == null) || !$scope.text.length) {
              return;
            }
            t = parseAnnotations($scope.text, $scope.annotations);
            return $scope.content = $sce.trustAsHtml(t);
          };
          $scope.$watch("text", onAnnotationsChange);
          $scope.$watch("annotations", onAnnotationsChange, true);
          options = {
            readonly: false,
            popupController: "",
            popupTemplateUrl: "",
            tooltipController: "",
            tooltipTemplateUrl: ""
          };
          options = angular.extend(options, $scope.options);
          clearPopup = function() {
            var tId;
            if (activePopup == null) {
              return;
            }
            tId = activePopup.scope.$annotation.id;
            return activePopup.destroy(function() {
              if (activePopup.scope.$annotation.id === tId) {
                return activePopup = null;
              }
            });
          };
          clearTooltip = function() {
            var tId;
            if (activeTooltip == null) {
              return;
            }
            tId = activeTooltip.scope.$annotation.id;
            return activeTooltip.destroy(function() {
              if (activeTooltip.scope.$annotation.id === tId) {
                return activeTooltip = null;
              }
            });
          };
          $scope.$on("$destroy", function() {
            clearPopup();
            return clearTooltip();
          });
          if (options.popupTemplateUrl) {
            $http.get(options.popupTemplateUrl).then(function(response) {
              return popupTemplateData = response.data;
            });
          }
          if (options.tooltipTemplateUrl) {
            $http.get(options.tooltipTemplateUrl).then(function(response) {
              return tooltipTemplateData = response.data;
            });
          }
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
            if (sel.isCollapsed) {
              throw new Error("NG_ANNOTATE_NO_TEXT_SELECTED");
            }
            range = sel.getRangeAt(0);
            if (range.startContainer !== range.endContainer) {
              throw new Error("NG_ANNOTATE_PARTIAL_NODE_SELECTED");
            }
            if (range.startContainer.parentNode.nodeName === "SPAN") {
              parentId = (attrId = range.startContainer.parentNode.getAttribute("data-annotation-id")) != null ? parseInt(attrId, 10) : void 0;
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
            clearSelection();
            return annotation;
          };
          clearSelection = function() {
            if (document.selection) {
              return document.selection.empty();
            } else if (window.getSelection && window.getSelection().empty) {
              return window.getSelection().empty();
            } else if (window.getSelection && window.getSelection().removeAllRanges) {
              return window.getSelection().removeAllRanges();
            }
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
            clearPopup();
            clearTooltip();
            return loadAnnotationPopup(annotation, $span, true);
          };
          onClick = function(event) {
            var $target, annotation, attrId, targetId;
            if (popupTemplateData.length === 0) {
              return;
            }
            $target = angular.element(event.target);
            targetId = (attrId = $target.attr("data-annotation-id")) != null ? parseInt(attrId, 10) : void 0;
            if (targetId == null) {
              return;
            }
            if ((activePopup != null) && activePopup.scope.$annotation.id === targetId) {
              clearPopup();
              return;
            }
            annotation = getAnnotationById($scope.annotations, targetId);
            clearPopup();
            clearTooltip();
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
            if ((activeTooltip != null) && activeTooltip.scope.$annotation.id === targetId) {
              activeTooltip.stopDestroy();
              return;
            } else {
              clearTooltip();
            }
            if (targetId == null) {
              return;
            }
            annotation = getAnnotationById($scope.annotations, targetId);
            if (activePopup != null) {
              return;
            }
            tooltip = new NGAnnotateTooltip($rootScope.$new());
            tooltip.scope.$annotation = annotation;
            tooltip.$anchor = $target;
            tooltip.scope.$reposition = function() {
              var leftPos, paddingLeft;
              tooltip.positionTop();
              paddingLeft = parseInt(element.css("padding-left"));
              leftPos = element.offset().left + paddingLeft - tooltip.$el.innerWidth() + LEFT_MARGIN;
              if (leftPos < 0) {
                leftPos = 0;
              }
              tooltip.positionLeft(leftPos);
            };
            activeTooltip = tooltip;
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
            tooltip.scope.$reposition();
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
            return clearTooltip();
          };
          loadAnnotationPopup = function(annotation, anchor, isNew) {
            var controller, locals, popup;
            popup = new NGAnnotatePopup($rootScope.$new());
            popup.scope.$isNew = isNew;
            popup.scope.$annotation = annotation;
            popup.scope.$readonly = options.readonly;
            popup.$anchor = anchor;
            popup.scope.$reject = function() {
              removeAnnotation(annotation.id, $scope.annotations);
              if ($scope.onAnnotateDelete != null) {
                $scope.onAnnotateDelete(annotation);
              }
              clearPopup();
            };
            popup.scope.$close = function() {
              if ($scope.onAnnotate != null) {
                $scope.onAnnotate(popup.scope.$annotation);
              }
              clearPopup();
            };
            popup.scope.$reposition = function() {
              var leftPos, paddingLeft;
              popup.positionTop();
              paddingLeft = parseInt(element.css("padding-left"));
              leftPos = element.offset().left + paddingLeft - popup.$el.innerWidth() + LEFT_MARGIN;
              if (leftPos < 0) {
                leftPos = 0;
              }
              popup.positionLeft(leftPos);
            };
            activePopup = popup;
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
            popup.scope.$reposition();
            popup.scope.$apply();
            return popup.show();
          };
          element.on("mouseenter", "span", onMouseEnter);
          element.on("mouseleave", "span", onMouseLeave);
          return element.on("mouseup", function(event) {
            var selection;
            selection = window.getSelection();
            if (!selection.isCollapsed && !options.readonly) {
              return onSelect(event);
            } else if (selection.isCollapsed && event.target.nodeName === "SPAN") {
              return onClick(event);
            } else if (selection.isCollapsed) {
              clearTooltip();
              return clearPopup();
            }
          });
        };
      }
    };
  });

}).call(this);
