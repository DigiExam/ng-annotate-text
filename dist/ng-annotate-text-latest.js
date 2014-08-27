(function() {
  var annotationIdCounter, getAnnotationById, insertAt, ngAnnotateText, parseAnnotations, sortAnnotationsByEndIndex;

  ngAnnotateText = angular.module("ngAnnotateText", []);

  annotationIdCounter = 0;

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
      text = insertAt(text, annotation.startIndex + indexOffset, "<span class=\"ng-annotate-text-annotation ng-annotate-text-" + annotation.id + " ng-annotate-text-type-" + annotation.type + "\" data-annotation-id=\"" + annotation.id + "\">");
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

  ngAnnotateText.factory("NGAnnotateTextPopup", function() {
    return function(args) {
      args = angular.extend({
        scope: null,
        callbacks: {},
        template: "<div/>",
        $anchor: null,
        preferredAxis: 'x',
        offset: 0,
        positionClass: '{{position}}'
      }, args);
      return angular.extend(this, args, {
        $el: angular.element(args.template),
        show: function(speed) {
          if (speed == null) {
            speed = "fast";
          }
          this.$el.fadeIn(speed);
          this.reposition();
          if (typeof this.callbacks.show === "function") {
            return this.callbacks.show(this.$el);
          }
        },
        hide: function(speed) {
          if (speed == null) {
            speed = "fast";
          }
          this.$el.fadeOut(speed);
          if (typeof this.callbacks.hide === "function") {
            return this.callbacks.hide(this.$el);
          }
        },
        isVisible: function() {
          return this.$el.is(":visible");
        },
        destroy: function(cb) {
          var $el, scope;
          if (cb == null) {
            cb = angular.noop;
          }
          scope = this.scope;
          $el = this.$el;
          return this.hide(function() {
            if (typeof cb === "function") {
              cb();
            }
            scope.$destroy();
            return $el.remove();
          });
        },
        stopDestroy: function() {
          return this.$el.stop(true).show("fast");
        },
        reposition: function() {
          var anchorEl, pos, posX, posY, targetEl;
          targetEl = this.$el[0];
          anchorEl = this.$anchor[0];
          if (!(targetEl || anchorEl)) {
            return;
          }
          pos = {
            left: null,
            top: null,
            target: targetEl.getBoundingClientRect(),
            anchor: anchorEl.getBoundingClientRect(),
            viewport: {
              width: window.innerWidth,
              height: window.innerHeight
            },
            scroll: {
              top: document.body.scrollTop,
              left: document.body.scrollLeft
            }
          };
          if (!(pos.target.width > 0 && pos.target.height > 0)) {
            return;
          }
          posX = this.getNewPositionOnAxis(pos, 'x');
          posY = this.getNewPositionOnAxis(pos, 'y');
          if (this.preferredAxis === 'x') {
            if (posX && typeof posX.pos === 'number') {
              pos.left = posX.pos;
              pos.edge = posX.edge;
            } else if (posY) {
              pos.top = posY.pos;
              pos.edge = posY.edge;
            }
          } else {
            if (posY && typeof posY.pos === 'number') {
              pos.top = posY.pos;
              pos.edge = posY.edge;
            } else if (posX) {
              pos.left = posX.pos;
              pos.edge = posX.edge;
            }
          }
          if (pos.left === null && pos.top === null) {
            pos.left = pos.scroll.left + (pos.viewport.width / 2) - (pos.target.width / 2);
            pos.top = pos.scroll.top + (pos.viewport.height / 2) - (pos.target.height / 2);
          } else if (pos.left === null) {
            pos.left = this.getNewCenterPositionOnAxis(pos, 'x');
          } else if (pos.top === null) {
            pos.top = this.getNewCenterPositionOnAxis(pos, 'y');
          }
          this.$el.addClass(pos.edge && this.positionClass.replace("{{position}}", pos.edge)).css({
            top: Math.round(pos.top) || 0,
            left: Math.round(pos.left) || 0
          });
        },
        getNewPositionOnAxis: function(pos, axis) {
          var axisPos, end, size, start;
          start = {
            x: 'left',
            y: 'top'
          }[axis];
          end = {
            x: 'right',
            y: 'bottom'
          }[axis];
          size = {
            x: 'width',
            y: 'height'
          }[axis];
          if (pos.anchor[start] - this.offset >= pos.target[size]) {
            axisPos = {
              pos: pos.scroll[start] + pos.anchor[start] - this.offset - pos.target[size],
              edge: start
            };
          } else if (pos.viewport[size] - pos.anchor[end] - this.offset >= pos.target[size]) {
            axisPos = {
              pos: pos.scroll[start] + pos.anchor[end] + this.offset,
              edge: end
            };
          }
          return axisPos;
        },
        getNewCenterPositionOnAxis: function(pos, axis) {
          var centerPos, size, start;
          start = {
            x: 'left',
            y: 'top'
          }[axis];
          size = {
            x: 'width',
            y: 'height'
          }[axis];
          centerPos = pos.scroll[start] + pos.anchor[start] + (pos.anchor[size] / 2) - (pos.target[size] / 2);
          return Math.max(pos.scroll[start] + this.offset, Math.min(centerPos, pos.scroll[start] + pos.viewport[size] - pos.target[size] - this.offset));
        }
      });
    };
  });

  ngAnnotateText.factory("NGAnnotation", function() {
    var Annotation;
    Annotation = function(data) {
      angular.extend(this, {
        id: annotationIdCounter++,
        startIndex: null,
        endIndex: null,
        data: {
          points: 0
        },
        type: "",
        children: []
      });
      if (data != null) {
        return angular.extend(this, data);
      }
    };
    return Annotation;
  });

  ngAnnotateText.directive("ngAnnotateText", function($rootScope, $compile, $http, $q, $controller, $sce, NGAnnotation, NGAnnotateTextPopup) {
    return {
      restrict: "E",
      scope: {
        text: "=",
        annotations: "=",
        readonly: "=",
        popupController: "=",
        popupTemplateUrl: "=",
        tooltipController: "=",
        tooltipTemplateUrl: "=",
        onAnnotate: "=",
        onAnnotateDelete: "=",
        onAnnotateError: "=",
        onPopupShow: "=",
        onPopupHide: "=",
        popupOffset: "="
      },
      template: "<p ng-bind-html=\"content\"></p>",
      replace: true,
      compile: function(el, attr) {
        if (attr.readonly == null) {
          attr.readonly = false;
        }
        return this.postLink;
      },
      postLink: function($scope, element, attrs) {
        var POPUP_OFFSET, activePopup, activeTooltip, clearPopup, clearPopups, clearSelection, clearTooltip, createAnnotation, loadAnnotationPopup, onAnnotationsChange, onClick, onMouseEnter, onMouseLeave, onSelect, popupTemplateData, removeAnnotation, removeChildren, tooltipTemplateData, _ref;
        POPUP_OFFSET = (_ref = $scope.popupOffset) != null ? _ref : 10;
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
          var tooltip;
          tooltip = activeTooltip;
          if (tooltip == null) {
            return;
          }
          return tooltip.destroy(function() {
            if (activeTooltip === tooltip) {
              return activeTooltip = null;
            }
          });
        };
        clearPopups = function() {
          clearPopup();
          return clearTooltip();
        };
        $scope.$on("$destroy", clearPopups);
        $scope.$on("ngAnnotateText.clearPopups", clearPopups);
        if ($scope.popupTemplateUrl) {
          $http.get($scope.popupTemplateUrl).then(function(response) {
            return popupTemplateData = response.data;
          });
        }
        if ($scope.tooltipTemplateUrl) {
          $http.get($scope.tooltipTemplateUrl).then(function(response) {
            return tooltipTemplateData = response.data;
          });
        }
        removeChildren = function(annotation) {
          var a, i, _i, _ref1, _results;
          _results = [];
          for (i = _i = _ref1 = annotation.children.length - 1; _i >= 0; i = _i += -1) {
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
            throw new Error("NG_ANNOTATE_TEXT_NO_TEXT_SELECTED");
          }
          range = sel.getRangeAt(0);
          if (range.startContainer !== range.endContainer) {
            throw new Error("NG_ANNOTATE_TEXT_PARTIAL_NODE_SELECTED");
          }
          if (range.startContainer.parentNode.nodeName === "SPAN") {
            parentId = (attrId = range.startContainer.parentNode.getAttribute("data-annotation-id")) != null ? parseInt(attrId, 10) : void 0;
            if (parentId === void 0) {
              throw new Error("NG_ANNOTATE_TEXT_ILLEGAL_SELECTION");
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
                throw new Error("NG_ANNOTATE_TEXT_ILLEGAL_SELECTION");
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
            $span = element.find(".ng-annotate-text-" + annotation.id);
          } catch (_error) {
            ex = _error;
            if ($scope.onAnnotateError != null) {
              $scope.onAnnotateError(ex);
            }
            return;
          }
          clearPopups();
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
          clearPopups();
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
          if ((activePopup != null) || (!annotation.data.comment && !annotation.data.points)) {
            return;
          }
          tooltip = new NGAnnotateTextPopup({
            scope: $rootScope.$new(),
            template: "<div class='ng-annotate-text-tooltip' />",
            positionClass: "ng-annotate-text-tooltip-docked ng-annotate-text-tooltip-docked-{{position}}",
            $anchor: $target,
            preferredAxis: 'y',
            offset: POPUP_OFFSET
          });
          tooltip.scope.$annotation = annotation;
          activeTooltip = tooltip;
          locals = {
            $scope: tooltip.scope,
            $template: tooltipTemplateData
          };
          tooltip.$el.html(locals.$template);
          tooltip.$el.appendTo("body");
          if ($scope.tooltipController) {
            controller = $controller($scope.tooltipController, locals);
            tooltip.$el.data("$ngControllerController", controller);
            tooltip.$el.children().data("$ngControllerController", controller);
          }
          $compile(tooltip.$el)(tooltip.scope);
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
          popup = new NGAnnotateTextPopup({
            scope: $rootScope.$new(),
            callbacks: {
              show: $scope.onPopupShow,
              hide: $scope.onPopupHide
            },
            template: "<div class='ng-annotate-text-popup' />",
            positionClass: "ng-annotate-text-popup-docked ng-annotate-text-popup-docked-{{position}}",
            $anchor: anchor,
            offset: POPUP_OFFSET
          });
          popup.scope.$isNew = isNew;
          popup.scope.$annotation = annotation;
          popup.scope.$readonly = $scope.readonly;
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
          activePopup = popup;
          locals = {
            $scope: popup.scope,
            $template: popupTemplateData
          };
          popup.$el.html(locals.$template);
          popup.$el.appendTo("body");
          if ($scope.popupController) {
            controller = $controller($scope.popupController, locals);
            popup.$el.data("$ngControllerController", controller);
            popup.$el.children().data("$ngControllerController", controller);
          }
          $compile(popup.$el)(popup.scope);
          popup.scope.$apply();
          return popup.show();
        };
        element.on("mouseenter", "span", onMouseEnter);
        element.on("mouseleave", "span", onMouseLeave);
        return element.on("mouseup", function(event) {
          var selection;
          selection = window.getSelection();
          if (!selection.isCollapsed && !$scope.readonly) {
            return onSelect(event);
          } else if (selection.isCollapsed && event.target.nodeName === "SPAN") {
            return onClick(event);
          } else if (selection.isCollapsed) {
            return clearPopups();
          }
        });
      }
    };
  });

}).call(this);

//# sourceMappingURL=ng-annotate-text-latest.js.map