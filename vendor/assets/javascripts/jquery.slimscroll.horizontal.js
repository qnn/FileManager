/*! Copyright (c) 2011 Piotr Rochala (http://rocha.la)
 * Dual licensed under the MIT (http://www.opensource.org/licenses/mit-license.php)
 * and GPL (http://www.opensource.org/licenses/gpl-license.php) licenses.
 *
 * Version: 1.2.0
 *
 */
(function($) {

  jQuery.fn.extend({
    slimScrollHorizontal: function(options) {

      var defaults = {
        wheelEnabled: false,

        // width in pixels of the visible scroll area
        width : '250px',

        // height in pixels of the visible scroll area
        height : 'auto',

        // width in pixels of the scrollbar and rail
        size : '7px',

        // scrollbar color, accepts any hex/color value
        color: '#000',

        // scrollbar position - left/right
        position : 'right',

        // distance in pixels between the side edge and the scrollbar
        distance : '1px',

        // default scroll position on load - left / right / $('selector')
        start : 'left',

        // sets scrollbar opacity
        opacity : .4,

        // enables always-on mode for the scrollbar
        alwaysVisible : true,

        // check if we should hide the scrollbar when user is hovering over
        disableFadeOut: false,

        // sets visibility of the rail
        railVisible : false,

        // sets rail color
        railColor : '#333',

        // sets rail opacity
        railOpacity : .2,

        // whether  we should use jQuery UI Draggable to enable bar dragging
        railDraggable : true,

        // defautlt CSS class of the slimscroll rail
        railClass : 'slimScrollHorizontalRail',

        // defautlt CSS class of the slimscroll bar
        barClass : 'TslimScrollHorizontalBar',

        // defautlt CSS class of the slimscroll wrapper
        wrapperClass : 'TslimScrollHorizontalDiv',

        // check if mousewheel should scroll the window if we reach left/right
        allowPageScroll : false,

        // scroll amount applied to each mouse wheel step
        wheelStep : 20,

        // scroll amount applied when user is using gestures
        touchScrollStep : 200
      };

      var o = $.extend(defaults, options);

      // do it for every element that matches selector
      this.each(function(){

      var isOverPanel, isOverBar, isDragg, queueHide, touchDif,
        barWidth, percentScroll, lastScroll,
        divS = '<div></div>',
        minBarWidth = 30,
        releaseScroll = false;

        // used in event handlers and for better minification
        var me = $(this);

        // ensure we are not binding it again
        if (me.parent().hasClass(o.wrapperClass))
        {
            // start from last bar position
            var offset = me.scrollLeft();

            // find bar and rail
            bar = me.parent().find('.' + o.barClass);
            rail = me.parent().find('.' + o.railClass);

            getBarWidth();

            // check if we should scroll existing instance
            if ($.isPlainObject(options))
            {
              // Pass width: auto to an existing slimscroll object to force a resize after contents have changed
              if ( 'width' in options && options.width == 'auto' ) {
                me.parent().css('width', 'auto');
                me.css('width', 'auto');
                var width = me.parent().parent().width();
                me.parent().css('width', width);
                me.css('width', width);
              }

              if ('scrollTo' in options)
              {
                // jump to a static point
                offset = parseInt(o.scrollTo);
              }
              else if ('scrollBy' in options)
              {
                // jump by value pixels
                offset += parseInt(o.scrollBy);
              }
              else if ('destroy' in options)
              {
                // remove slimscroll elements
                bar.remove();
                rail.remove();
                me.unwrap();
                return;
              }

              // scroll content by the given offset
              scrollContent(offset, false, true);
            }

            return;
        }

        // optionally set width to the parent's width
        o.width = (o.width == 'auto') ? me.parent().width() : o.width;

        // wrap content
        var wrapper = $(divS)
          .addClass(o.wrapperClass)
          .css({
            position: 'relative',
            overflow: 'hidden',
            width: o.width,
            height: o.height
          });

        // update style for the div
        me.css({
          overflow: 'hidden',
          width: o.width,
          height: o.height
        });

        // create scrollbar rail
        var rail = $(divS)
          .addClass(o.railClass)
          .css({
            width: '100%',
            height: o.size,
            position: 'absolute',
            left: 0,
            bottom: 1,
            display: (o.alwaysVisible && o.railVisible) ? 'block' : 'none',
            'border-radius': o.size,
            background: o.railColor,
            opacity: o.railOpacity,
            zIndex: 90
          });

        // create scrollbar
        var bar = $(divS)
          .addClass(o.barClass)
          .css({
            background: o.color,
            width: o.size,
            height: o.size,
            position: 'absolute',
            left: 0,
            bottom: 1,
            opacity: o.opacity,
            display: o.alwaysVisible ? 'block' : 'none',
            'border-radius' : o.size,
            BorderRadius: o.size,
            MozBorderRadius: o.size,
            WebkitBorderRadius: o.size,
            zIndex: 99
          });

        // set position
        var posCss = (o.position == 'right') ? { right: o.distance } : { left: o.distance };
        rail.css(posCss);
        bar.css(posCss);

        // wrap it
        me.wrap(wrapper);

        // append to parent div
        me.parent().append(bar);
        me.parent().append(rail);

        // make it draggable
        if (o.railDraggable && $.ui && typeof($.ui.draggable) == 'function')
        {
          bar.draggable({
            axis: 'x',
            containment: 'parent',
            start: function() { isDragg = true; },
            stop: function() { isDragg = false; hideBar(); },
            drag: function(e)
            {
              // scroll content
              scrollContent(0, $(this).position().left, false);
            }
          });
        }

        // on rail over
        rail.hover(function(){
          showBar();
        }, function(){
          hideBar();
        });

        // on bar over
        bar.hover(function(){
          isOverBar = true;
        }, function(){
          isOverBar = false;
        });

        // show on parent mouseover
        me.hover(function(){
          isOverPanel = true;
          showBar();
          hideBar();
        }, function(){
          isOverPanel = false;
          hideBar();
        });

        // support for mobile
        me.bind('touchstart', function(e,b){
          if (e.originalEvent.touches.length)
          {
            // record where touch started
            touchDif = e.originalEvent.touches[0].pageY;
          }
        });

        me.bind('touchmove', function(e){
          // prevent scrolling the page
          e.originalEvent.preventDefault();
          if (e.originalEvent.touches.length)
          {
            // see how far user swiped
            var diff = (touchDif - e.originalEvent.touches[0].pageY) / o.touchScrollStep;
            // scroll content
            scrollContent(diff, true);
          }
        });

        // check start position
        if (o.start === 'right')
        {
          // scroll content to right
          bar.css({ left: me.outerWidth() - bar.outerWidth() });
          scrollContent(0, true);
        }
        else if (o.start !== 'left')
        {
          // assume jQuery selector
          scrollContent($(o.start).position().left, null, true);

          // make sure bar stays hidden
          if (!o.alwaysVisible) { bar.hide(); }
        }

        // attach scroll events
        if (o.wheelEnabled) attachWheel();

        // set up initial width
        getBarWidth();

        function _onWheel(e)
        {
          // use mouse wheel only when mouse is over
          if (!isOverPanel) { return; }

          var e = e || window.event;

          var delta = 0;
          if (e.wheelDelta) { delta = -e.wheelDelta/120; }
          if (e.detail) { delta = e.detail / 3; }

          var target = e.target || e.srcTarget || e.srcElement;
          if ($(target).closest('.' + o.wrapperClass).is(me.parent())) {
            // scroll content
            scrollContent(delta, true);
          }

          // stop window scroll
          if (e.preventDefault && !releaseScroll) { e.preventDefault(); }
          if (!releaseScroll) { e.returnValue = false; }
        }

        function scrollContent(y, isWheel, isJump)
        {
          var delta = y;
          var maxLeft = me.outerWidth() - bar.outerWidth();

          if (isWheel)
          {
            // move bar with mouse wheel
            delta = parseInt(bar.css('left')) + y * parseInt(o.wheelStep) / 100 * bar.outerWidth();

            // move bar, make sure it doesn't go out
            delta = Math.min(Math.max(delta, 0), maxLeft);

            // if scrolling down, make sure a fractional change to the
            // scroll position isn't rounded away when the scrollbar's CSS is set
            // this flooring of delta would happened automatically when
            // bar.css is set below, but we floor here for clarity
            delta = (y > 0) ? Math.ceil(delta) : Math.floor(delta);

            // scroll the scrollbar
            bar.css({ left: delta + 'px' });
          }

          // calculate actual scroll amount
          percentScroll = parseInt(bar.css('left')) / (me.outerWidth() - bar.outerWidth());
          delta = percentScroll * (me[0].scrollWidth - me.outerWidth());

          if (isJump)
          {
            delta = y;
            var offsetLeft = delta / me[0].scrollWidth * me.outerWidth();
            offsetLeft = Math.min(Math.max(offsetLeft, 0), maxLeft);
            bar.css({ left: offsetLeft + 'px' });
          }

          // scroll content
          me.scrollLeft(delta);

          // fire scrolling event
          me.trigger('slimscrolling', ~~delta);

          // ensure bar is visible
          showBar();

          // trigger hide when scroll is stopped
          hideBar();
        }

        function attachWheel()
        {
          if (window.addEventListener)
          {
            this.addEventListener('DOMMouseScroll', _onWheel, false );
            this.addEventListener('mousewheel', _onWheel, false );
          }
          else
          {
            document.attachEvent("onmousewheel", _onWheel)
          }
        }

        function getBarWidth()
        {
          // calculate scrollbar width and make sure it is not too small
          barWidth = Math.max((me.outerWidth() / me[0].scrollWidth) * me.outerWidth(), minBarWidth);
          bar.css({ width: barWidth + 'px' });

          // hide scrollbar if content is not long enough
          var display = barWidth == me.outerWidth() ? 'none' : 'block';
          bar.css({ display: display });
        }

        function showBar()
        {
          // recalculate bar width
          getBarWidth();
          clearTimeout(queueHide);

          // when bar reached left or right
          if (percentScroll == ~~percentScroll)
          {
            //release wheel
            releaseScroll = o.allowPageScroll;

            // publish approporiate event
            if (lastScroll != percentScroll)
            {
                var msg = (~~percentScroll == 0) ? 'left' : 'right';
                me.trigger('slimscroll', msg);
            }
          }
          else
          {
            releaseScroll = false;
          }
          lastScroll = percentScroll;

          // show only when required
          if(barWidth >= me.outerWidth()) {
            //allow window scroll
            releaseScroll = true;
            return;
          }
          bar.stop(true,true).fadeIn('fast');
          if (o.railVisible) { rail.stop(true,true).fadeIn('fast'); }
        }

        function hideBar()
        {
          // only hide when options allow it
          if (!o.alwaysVisible)
          {
            queueHide = setTimeout(function(){
              if (!(o.disableFadeOut && isOverPanel) && !isOverBar && !isDragg)
              {
                bar.fadeOut('slow');
                rail.fadeOut('slow');
              }
            }, 1000);
          }
        }

      });

      // maintain chainability
      return this;
    }
  });

  jQuery.fn.extend({
    slimScrollHorizontal: jQuery.fn.slimScrollHorizontal
  });

})(jQuery);
