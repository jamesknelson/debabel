# The publicly visible API. Note that this.operation(f) wraps
# a method in an operation, delaying updates to the display
# until completion.
class PatternEditor

  # Get the current editor content
  getPattern: -> @view.pattern
  setPattern: @operation (pattern) ->
    this._updatePatternInner 0, @view.pattern.length-1, pattern, 0, 0, "setValue"

  getSelection: -> this.getRange @view.sel.from, @view.sel.to
  replaceSelection: @operation (pattern, collapse, origin) ->
    this._updatePattern @view.sel.from, @view.sel.to, pattern, collapse || "around", origin

  focus: ->
    window.focus()
    this._focusInput()
    this._onFocus()
    this._fastPoll()

  getOption: (key) -> @options[key]
  setOption: (key, value) ->
    old = @options[key]
    return if @options[key] == value && key != "mode"
    options[key] = value

    if PatternEditor.optionHandlers.hasOwnProperty key
      (@operation PatternEditor.optionHandlers[key])(this, value, old)

  getMode: -> @view.mode

  undo: @operation -> this._travelHistory "undo"
  redo: @operation -> this._travelHistory "redo"

  markClean: -> @history.dirtyCounter = 0
  isClean: function () {return this.view.history.dirtyCounter == 0;},
    
  historySize: -> undo: @history.done.length, redo: @history.undone.length

  clearHistory: -> this._makeHistory()
  getHistory: ->
    # TODO
    cp = (arr) ->
      for (var i = 0, nw = [], nwelt; i < arr.length; ++i) {
        var set = arr[i];
        nw.push({events: nwelt = [], fromBefore: set.fromBefore, toBefore: set.toBefore,
                 fromAfter: set.fromAfter, toAfter: set.toAfter});
        for (var j = 0, elt = set.events; j < elt.length; ++j) {
          var old = [], cur = elt[j];
          nwelt.push({start: cur.start, added: cur.added, old: old});
          for (var k = 0; k < cur.old.length; ++k) old.push(hlText(cur.old[k]));
        }
      }
      nw

    done: cp(hist.done), undone: cp(hist.undone)
  setHistory: (historyData) ->
    this._makeHistory()
    @history.done = historyData.done
    @history.undone = historyData.undone

  # Fetch the parser token for a given character. Useful for hacks
  # that want to inspect the mode state (say, for completion).
  getTokenAt: function(pos) {
    var doc = this.view.doc;
    pos = clipPos(doc, pos);
    var state = getStateBefore(this, pos.line), mode = this.view.mode;
    var line = getLine(doc, pos.line);
    var stream = new StringStream(line.text, this.options.tabSize);
    while (stream.pos < pos.ch && !stream.eol()) {
      stream.start = stream.pos;
      var style = mode.token(stream, state);
    }
    return {start: stream.start,
            end: stream.pos,
            string: stream.current(),
            className: style || null, // Deprecated, use 'type' instead
            type: style || null,
            state: state};
  },

  getStateAfter: function(line) {
    var doc = this.view.doc;
    line = clipLine(doc, line == null ? doc.size - 1: line);
    return getStateBefore(this, line + 1);
  },

  cursorCoords: function(start, mode) {
    var pos, sel = this.view.sel;
    if (start == null) pos = sel.head;
    else if (typeof start == "object") pos = clipPos(this.view.doc, start);
    else pos = start ? sel.from : sel.to;
    return cursorCoords(this, pos, mode || "page");
  },

  charCoords: function(pos, mode) {
    return charCoords(this, clipPos(this.view.doc, pos), mode || "page");
  },

  coordsChar: function(coords) {
    var off = this.display.lineSpace.getBoundingClientRect();
    return coordsChar(this, coords.left - off.left, coords.top - off.top);
  },

  defaultTextHeight: function() { return textHeight(this.display); },

  markText: operation(null, function(from, to, options) {
    return markText(this, clipPos(this.view.doc, from), clipPos(this.view.doc, to),
                    options, "range");
  }),

  setBookmark: operation(null, function(pos, widget) {
    pos = clipPos(this.view.doc, pos);
    return markText(this, pos, pos, widget ? {replacedWith: widget} : {}, "bookmark");
  }),

  findMarksAt: function(pos) {
    var doc = this.view.doc;
    pos = clipPos(doc, pos);
    var markers = [], spans = getLine(doc, pos.line).markedSpans;
    if (spans) for (var i = 0; i < spans.length; ++i) {
      var span = spans[i];
      if ((span.from == null || span.from <= pos.ch) &&
          (span.to == null || span.to >= pos.ch))
        markers.push(span.marker);
    }
    return markers;
  },

  getViewport: function() { return {from: this.display.showingFrom, to: this.display.showingTo};},

  addWidget: function(pos, node, scroll, vert, horiz) {
    var display = this.display;
    pos = cursorCoords(this, clipPos(this.view.doc, pos));
    var top = pos.top, left = pos.left;
    node.style.position = "absolute";
    display.sizer.appendChild(node);
    if (vert == "over") top = pos.top;
    else if (vert == "near") {
      var vspace = Math.max(display.wrapper.clientHeight, this.view.doc.height),
      hspace = Math.max(display.sizer.clientWidth, display.lineSpace.clientWidth);
      if (pos.bottom + node.offsetHeight > vspace && pos.top > node.offsetHeight)
        top = pos.top - node.offsetHeight;
      if (left + node.offsetWidth > hspace)
        left = hspace - node.offsetWidth;
    }
    node.style.top = (top + paddingTop(display)) + "px";
    node.style.left = node.style.right = "";
    if (horiz == "right") {
      left = display.sizer.clientWidth - node.offsetWidth;
      node.style.right = "0px";
    } else {
      if (horiz == "left") left = 0;
      else if (horiz == "middle") left = (display.sizer.clientWidth - node.offsetWidth) / 2;
      node.style.left = left + "px";
    }
    if (scroll)
      scrollIntoView(this, left, top, left + node.offsetWidth, top + node.offsetHeight);
  },

  patternLength: -> @view.pattern.length

  clipPos: function(pos) {return clipPos(this.view.doc, pos);},

  getCursor: function(start) {
    var sel = this.view.sel, pos;
    if (start == null || start == "head") pos = sel.head;
    else if (start == "anchor") pos = sel.anchor;
    else if (start == "end" || start === false) pos = sel.to;
    else pos = sel.from;
    return copyPos(pos);
  },

  somethingSelected: function() {return !posEq(this.view.sel.from, this.view.sel.to);},

  setCursor: operation(null, function(line, ch, extend) {
    var pos = clipPos(this.view.doc, typeof line == "number" ? {line: line, ch: ch || 0} : line);
    if (extend) extendSelection(this, pos);
    else setSelection(this, pos, pos);
  }),

  setSelection: operation(null, function(anchor, head) {
    var doc = this.view.doc;
    setSelection(this, clipPos(doc, anchor), clipPos(doc, head || anchor));
  }),

  extendSelection: operation(null, function(from, to) {
    var doc = this.view.doc;
    extendSelection(this, clipPos(doc, from), to && clipPos(doc, to));
  }),

  setExtending: function(val) {this.view.sel.extend = val;},

  replaceRange: operation(null, function(code, from, to) {
    var doc = this.view.doc;
    from = clipPos(doc, from);
    to = to ? clipPos(doc, to) : from;
    return replaceRange(this, code, from, to);
  }),

  getRange: function(from, to, lineSep) {
    var doc = this.view.doc;
    from = clipPos(doc, from); to = clipPos(doc, to);
    var l1 = from.line, l2 = to.line;
    if (l1 == l2) return getLine(doc, l1).text.slice(from.ch, to.ch);
    var code = [getLine(doc, l1).text.slice(from.ch)];
    doc.iter(l1 + 1, l2, function(line) { code.push(line.text); });
    code.push(getLine(doc, l2).text.slice(0, to.ch));
    return code.join(lineSep || "\n");
  },

  triggerOnKeyDown: operation(null, onKeyDown),

  execCommand: function(cmd) {return commands[cmd](this);},

  // Stuff used by commands, probably not much use to outside code.
  moveH: operation(null, function(dir, unit) {
    var sel = this.view.sel, pos = dir < 0 ? sel.from : sel.to;
    if (sel.shift || sel.extend || posEq(sel.from, sel.to)) pos = findPosH(this, dir, unit, true);
    extendSelection(this, pos, pos, dir);
  }),

  deleteH: operation(null, function(dir, unit) {
    var sel = this.view.sel;
    if (!posEq(sel.from, sel.to)) replaceRange(this, "", sel.from, sel.to, "delete");
    else replaceRange(this, "", sel.from, findPosH(this, dir, unit, false), "delete");
    this.curOp.userSelChange = true;
  }),

  scrollTo: function(x, y) {
    if (x != null) this.display.scrollbarH.scrollLeft = this.display.scroller.scrollLeft = x;
    if (y != null) this.display.scrollbarV.scrollTop = this.display.scroller.scrollTop = y;
    updateDisplay(this, []);
  },
  getScrollInfo: function() {
    var scroller = this.display.scroller, co = scrollerCutOff;
    return {left: scroller.scrollLeft, top: scroller.scrollTop,
            height: scroller.scrollHeight - co, width: scroller.scrollWidth - co,
            clientHeight: scroller.clientHeight - co, clientWidth: scroller.clientWidth - co};
  },

  scrollIntoView: function(pos) {
    pos = pos ? clipPos(this.view.doc, pos) : this.view.sel.head;
    var coords = cursorCoords(this, pos);
    scrollIntoView(this, coords.left, coords.top, coords.left, coords.bottom);
  },

  setSize: function(width, height) {
    function interpret(val) {
      return typeof val == "number" || /^\d+$/.test(String(val)) ? val + "px" : val;
    }
    if (width != null) this.display.wrapper.style.width = interpret(width);
    if (height != null) this.display.wrapper.style.height = interpret(height);
    this.refresh();
  },

  on: function(type, f) {on(this, type, f);},
  off: function(type, f) {off(this, type, f);},

  operation: function(f){return operation(this, f)();},

  refresh: function() {
    clearMeasureLineCache(this);
    if (this.display.scroller.scrollHeight > this.view.scrollTop)
      this.display.scrollbarV.scrollTop = this.display.scroller.scrollTop = this.view.scrollTop;
    updateDisplay(this, true);
  },

  getInputField: function(){return this.display.input;},
  getWrapperElement: function(){return this.display.wrapper;},
  getScrollerElement: function(){return this.display.scroller;}