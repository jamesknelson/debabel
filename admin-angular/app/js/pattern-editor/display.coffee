class PatternEditor
  makeDisplay: ->
    d = @display = {}

    d.input = make "input", attributes: {autocorrect: "off", autocapitalize: "off"}
    d.inputWrapper = make "div", "PE-input-wrapper", child: d.input
    d.measurer = make "div", "PE-measurer"
    d.selection = make "div", "PE-selection"
    d.content = make "div"
    d.cursor = make "pre", "PE-cursor", text: "\u00a0"
    d.contentWrapper = make "div", "PE-content-wrapper", children: [d.measurer, d.selection, d.content, d.cursor]

    # The div which contains the entire editor
    d.editor = make "div", "PE", children: [d.inputWrapper, d.contentWrapper]
    d.editor.PatternEditor = this

    # Add the editor to the DOM
    @input.parentNode.insertBefore editor, @input.nextSibling

    # Needed to hide big blue blinking cursor on Mobile Safari
    d.input.style.width = "0px" if ios

    # Needed to handle Tab key in KHTML
    if khtml
      d.inputWrapper.style.height = "1px"
      d.inputWrapper.style.position = "absolute"
    
    # Current visible range (may be bigger than the view window).
    d.viewOffset = d.showingFrom = d.showingTo = d.lastSizeC = 0

    # See readInput and resetInput
    d.prevInput = ""

    # Flag that indicates whether we currently expect input to appear
    # (after some event like 'keypress' or 'input') and are polling
    # intensively.
    d.pollingFast = false

    # Self-resetting timeout for the poller
    d.poll = new Timer

    # Used to adjust overwrite behaviour when a paste has been
    # detected
    d.pasteIncoming = false

  function updateDisplay(cm, changes, viewPort) {
    var oldFrom = cm.display.showingFrom, oldTo = cm.display.showingTo;
    var updated = updateDisplayInner(cm, changes, viewPort);
    if (updated) {
      signalLater(cm, cm, "update", cm);
      if (cm.display.showingFrom != oldFrom || cm.display.showingTo != oldTo)
        signalLater(cm, cm, "viewportChange", cm, cm.display.showingFrom, cm.display.showingTo);
    }
    updateSelection(cm);
    updateScrollbars(cm.display, cm.view.doc.height);

    return updated;
  }

  // Uses a set of changes plus the current scroll position to
  // determine which DOM updates have to be made, and makes the
  // updates.
  function updateDisplayInner(cm, changes, viewPort) {
    var display = cm.display, doc = cm.view.doc;
    if (!display.wrapper.clientWidth) {
      display.showingFrom = display.showingTo = display.viewOffset = 0;
      return;
    }

    // Compute the new visible window
    // If scrollTop is specified, use that to determine which lines
    // to render instead of the current scrollbar position.
    var visible = visibleLines(display, doc, viewPort);
    // Bail out if the visible area is already rendered and nothing changed.
    if (changes !== true && changes.length == 0 &&
        visible.from > display.showingFrom && visible.to < display.showingTo)
      return;

    if (changes && maybeUpdateLineNumberWidth(cm))
      changes = true;
    display.sizer.style.marginLeft = display.scrollbarH.style.left = display.gutters.offsetWidth + "px";

    // When merged lines are present, the line that needs to be
    // redrawn might not be the one that was changed.
    if (changes !== true && sawCollapsedSpans)
      for (var i = 0; i < changes.length; ++i) {
        var ch = changes[i], merged;
        while (merged = collapsedSpanAtStart(getLine(doc, ch.from))) {
          var from = merged.find().from.line;
          if (ch.diff) ch.diff -= ch.from - from;
          ch.from = from;
        }
      }

    // Used to determine which lines need their line numbers updated
    var positionsChangedFrom = changes === true ? 0 : Infinity;
    if (cm.options.lineNumbers && changes && changes !== true)
      for (var i = 0; i < changes.length; ++i)
        if (changes[i].diff) { positionsChangedFrom = changes[i].from; break; }

    var from = Math.max(visible.from - cm.options.viewportMargin, 0);
    var to = Math.min(doc.size, visible.to + cm.options.viewportMargin);
    if (display.showingFrom < from && from - display.showingFrom < 20) from = display.showingFrom;
    if (display.showingTo > to && display.showingTo - to < 20) to = Math.min(doc.size, display.showingTo);
    if (sawCollapsedSpans) {
      from = lineNo(visualLine(doc, getLine(doc, from)));
      while (to < doc.size && lineIsHidden(getLine(doc, to))) ++to;
    }

    // Create a range of theoretically intact lines, and punch holes
    // in that using the change info.
    var intact = changes === true ? [] :
      computeIntact([{from: display.showingFrom, to: display.showingTo}], changes);
    // Clip off the parts that won't be visible
    var intactLines = 0;
    for (var i = 0; i < intact.length; ++i) {
      var range = intact[i];
      if (range.from < from) range.from = from;
      if (range.to > to) range.to = to;
      if (range.from >= range.to) intact.splice(i--, 1);
      else intactLines += range.to - range.from;
    }
    if (intactLines == to - from && from == display.showingFrom && to == display.showingTo)
      return;
    intact.sort(function(a, b) {return a.from - b.from;});

    if (intactLines < (to - from) * .7) display.lineDiv.style.display = "none";
    patchDisplay(cm, from, to, intact, positionsChangedFrom);
    display.lineDiv.style.display = "";

    var different = from != display.showingFrom || to != display.showingTo ||
      display.lastSizeC != display.wrapper.clientHeight;
    // This is just a bogus formula that detects when the editor is
    // resized or the font size changes.
    if (different) display.lastSizeC = display.wrapper.clientHeight;
    display.showingFrom = from; display.showingTo = to;
    startWorker(cm, 100);

    var prevBottom = display.lineDiv.offsetTop;
    for (var node = display.lineDiv.firstChild, height; node; node = node.nextSibling) if (node.lineObj) {
      if (ie_lt8) {
        var bot = node.offsetTop + node.offsetHeight;
        height = bot - prevBottom;
        prevBottom = bot;
      } else {
        var box = node.getBoundingClientRect();
        height = box.bottom - box.top;
      }
      var diff = node.lineObj.height - height;
      if (height < 2) height = textHeight(display);
      if (diff > .001 || diff < -.001)
        updateLineHeight(node.lineObj, height);
    }
    display.viewOffset = heightAtLine(cm, getLine(doc, from));
    // Position the mover div to align with the current virtual scroll position
    display.mover.style.top = display.viewOffset + "px";
    return true;
  }

  function computeIntact(intact, changes) {
    for (var i = 0, l = changes.length || 0; i < l; ++i) {
      var change = changes[i], intact2 = [], diff = change.diff || 0;
      for (var j = 0, l2 = intact.length; j < l2; ++j) {
        var range = intact[j];
        if (change.to <= range.from && change.diff) {
          intact2.push({from: range.from + diff, to: range.to + diff});
        } else if (change.to <= range.from || change.from >= range.to) {
          intact2.push(range);
        } else {
          if (change.from > range.from)
            intact2.push({from: range.from, to: change.from});
          if (change.to < range.to)
            intact2.push({from: change.to + diff, to: range.to + diff});
        }
      }
      intact = intact2;
    }
    return intact;
  }

  function getDimensions(cm) {
    var d = cm.display, left = {}, width = {};
    for (var n = d.gutters.firstChild, i = 0; n; n = n.nextSibling, ++i) {
      left[cm.options.gutters[i]] = n.offsetLeft;
      width[cm.options.gutters[i]] = n.offsetWidth;
    }
    return {fixedPos: compensateForHScroll(d),
            gutterTotalWidth: d.gutters.offsetWidth,
            gutterLeft: left,
            gutterWidth: width,
            wrapperWidth: d.wrapper.clientWidth};
  }

  function patchDisplay(cm, from, to, intact, updateNumbersFrom) {
    var dims = getDimensions(cm);
    var display = cm.display, lineNumbers = cm.options.lineNumbers;
    // IE does bad things to nodes when .innerHTML = "" is used on a parent
    // we still need widgets and markers intact to add back to the new content later
    if (!intact.length && !ie && (!webkit || !cm.display.currentWheelTarget))
      removeChildren(display.lineDiv);
    var container = display.lineDiv, cur = container.firstChild;

    function rm(node) {
      var next = node.nextSibling;
      if (webkit && mac && cm.display.currentWheelTarget == node) {
        node.style.display = "none";
        node.lineObj = null;
      } else {
        container.removeChild(node);
      }
      return next;
    }

    var nextIntact = intact.shift(), lineNo = from;
    cm.view.doc.iter(from, to, function(line) {
      if (nextIntact && nextIntact.to == lineNo) nextIntact = intact.shift();
      if (lineIsHidden(line)) {
        if (line.height != 0) updateLineHeight(line, 0);
      } else if (nextIntact && nextIntact.from <= lineNo && nextIntact.to > lineNo) {
        // This line is intact. Skip to the actual node. Update its
        // line number if needed.
        while (cur.lineObj != line) cur = rm(cur);
        if (lineNumbers && updateNumbersFrom <= lineNo && cur.lineNumber)
          setTextContent(cur.lineNumber, lineNumberFor(cm.options, lineNo));
        cur = cur.nextSibling;
      } else {
        // This line needs to be generated.
        var lineNode = buildLineElement(cm, line, lineNo, dims);
        container.insertBefore(lineNode, cur);
        lineNode.lineObj = line;
      }
      ++lineNo;
    });
    while (cur) cur = rm(cur);
  }

  function buildLineElement(cm, line, lineNo, dims) {
    var lineElement = lineContent(cm, line);
    var markers = line.gutterMarkers, display = cm.display;

    if (!cm.options.lineNumbers && !markers && !line.bgClass && !line.wrapClass &&
        (!line.widgets || !line.widgets.length)) return lineElement;

    // Lines with gutter elements or a background class need
    // to be wrapped again, and have the extra elements added
    // to the wrapper div

    var wrap = elt("div", null, line.wrapClass, "position: relative");
    if (cm.options.lineNumbers || markers) {
      var gutterWrap = wrap.appendChild(elt("div", null, null, "position: absolute; left: " +
                                            dims.fixedPos + "px"));
      wrap.alignable = [gutterWrap];
      if (cm.options.lineNumbers && (!markers || !markers["CodeMirror-linenumbers"]))
        wrap.lineNumber = gutterWrap.appendChild(
          elt("div", lineNumberFor(cm.options, lineNo),
              "CodeMirror-linenumber CodeMirror-gutter-elt",
              "left: " + dims.gutterLeft["CodeMirror-linenumbers"] + "px; width: "
              + display.lineNumInnerWidth + "px"));
      if (markers)
        for (var k = 0; k < cm.options.gutters.length; ++k) {
          var id = cm.options.gutters[k], found = markers.hasOwnProperty(id) && markers[id];
          if (found)
            gutterWrap.appendChild(elt("div", [found], "CodeMirror-gutter-elt", "left: " +
                                       dims.gutterLeft[id] + "px; width: " + dims.gutterWidth[id] + "px"));
        }
    }
    // Kludge to make sure the styled element lies behind the selection (by z-index)
    if (line.bgClass)
      wrap.appendChild(elt("div", "\u00a0", line.bgClass + " CodeMirror-linebackground"));
    wrap.appendChild(lineElement);
    if (line.widgets)
      for (var i = 0, ws = line.widgets; i < ws.length; ++i) {
        var widget = ws[i], node = elt("div", [widget.node], "CodeMirror-linewidget");
        node.widget = widget;
        if (widget.noHScroll) {
          (wrap.alignable || (wrap.alignable = [])).push(node);
          var width = dims.wrapperWidth;
          node.style.left = dims.fixedPos + "px";
          if (!widget.coverGutter) {
            width -= dims.gutterTotalWidth;
            node.style.paddingLeft = dims.gutterTotalWidth + "px";
          }
          node.style.width = width + "px";
        }
        if (widget.coverGutter) {
          node.style.zIndex = 5;
          node.style.position = "relative";
          if (!widget.noHScroll) node.style.marginLeft = -dims.gutterTotalWidth + "px";
        }
        if (widget.above)
          wrap.insertBefore(node, cm.options.lineNumbers && line.height != 0 ? gutterWrap : lineElement);
        else
          wrap.appendChild(node);
      }

    if (ie_lt8) wrap.style.zIndex = 2;
    return wrap;
  }