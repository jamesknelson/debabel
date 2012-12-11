function mouseEventInWidget(display, e) {
  for (var n = e_target(e); n != display.wrapper; n = n.parentNode)
    if (/\bCodeMirror-(?:line)?widget\b/.test(n.className) ||
        n.parentNode == display.sizer && n != display.mover) return true;
}

function posFromMouse(cm, e, liberal) {
  var display = cm.display;
  if (!liberal) {
    var target = e_target(e);
    if (target == display.scrollbarH || target == display.scrollbarH.firstChild ||
        target == display.scrollbarV || target == display.scrollbarV.firstChild ||
        target == display.scrollbarFiller) return null;
  }
  var x, y, space = display.lineSpace.getBoundingClientRect();
  // Fails unpredictably on IE[67] when mouse is dragged around quickly.
  try { x = e.clientX; y = e.clientY; } catch (e) { return null; }
  return coordsChar(cm, x - space.left, y - space.top);
}

var lastClick, lastDoubleClick;
function onMouseDown(e) {
  var cm = this, display = cm.display, view = cm.view, sel = view.sel, doc = view.doc;
  sel.shift = e_prop(e, "shiftKey");

  if (mouseEventInWidget(display, e)) {
    if (!webkit) {
      display.scroller.draggable = false;
      setTimeout(function(){display.scroller.draggable = true;}, 100);
    }
    return;
  }
  if (clickInGutter(cm, e)) return;
  var start = posFromMouse(cm, e);

  switch (e_button(e)) {
  case 3:
    if (gecko) onContextMenu.call(cm, cm, e);
    return;
  case 2:
    if (start) extendSelection(cm, start);
    setTimeout(bind(focusInput, cm), 20);
    e_preventDefault(e);
    return;
  }
  // For button 1, if it was clicked inside the editor
  // (posFromMouse returning non-null), we have to adjust the
  // selection.
  if (!start) {if (e_target(e) == display.scroller) e_preventDefault(e); return;}

  if (!view.focused) onFocus(cm);

  var now = +new Date, type = "single";
  if (lastDoubleClick && lastDoubleClick.time > now - 400 && posEq(lastDoubleClick.pos, start)) {
    type = "triple";
    e_preventDefault(e);
    setTimeout(bind(focusInput, cm), 20);
    selectLine(cm, start.line);
  } else if (lastClick && lastClick.time > now - 400 && posEq(lastClick.pos, start)) {
    type = "double";
    lastDoubleClick = {time: now, pos: start};
    e_preventDefault(e);
    var word = findWordAt(getLine(doc, start.line).text, start);
    extendSelection(cm, word.from, word.to);
  } else { lastClick = {time: now, pos: start}; }

  var last = start;
  if (cm.options.dragDrop && dragAndDrop && !isReadOnly(cm) && !posEq(sel.from, sel.to) &&
      !posLess(start, sel.from) && !posLess(sel.to, start) && type == "single") {
    var dragEnd = operation(cm, function(e2) {
      if (webkit) display.scroller.draggable = false;
      view.draggingText = false;
      off(document, "mouseup", dragEnd);
      off(display.scroller, "drop", dragEnd);
      if (Math.abs(e.clientX - e2.clientX) + Math.abs(e.clientY - e2.clientY) < 10) {
        e_preventDefault(e2);
        extendSelection(cm, start);
        focusInput(cm);
      }
    });
    // Let the drag handler handle this.
    if (webkit) display.scroller.draggable = true;
    view.draggingText = dragEnd;
    // IE's approach to draggable
    if (display.scroller.dragDrop) display.scroller.dragDrop();
    on(document, "mouseup", dragEnd);
    on(display.scroller, "drop", dragEnd);
    return;
  }
  e_preventDefault(e);
  if (type == "single") extendSelection(cm, start);

  var startstart = sel.from, startend = sel.to;

  function doSelect(cur) {
    if (type == "single") {
      extendSelection(cm, start, cur);
    } else if (type == "double") {
      var word = findWordAt(getLine(doc, cur.line).text, cur);
      if (posLess(cur, startstart)) extendSelection(cm, word.from, startend);
      else extendSelection(cm, startstart, word.to);
    } else if (type == "triple") {
      if (posLess(cur, startstart)) extendSelection(cm, startend, clipPos(doc, {line: cur.line, ch: 0}));
      else extendSelection(cm, startstart, clipPos(doc, {line: cur.line + 1, ch: 0}));
    }
  }

  var editorSize = display.wrapper.getBoundingClientRect();
  // Used to ensure timeout re-tries don't fire when another extend
  // happened in the meantime (clearTimeout isn't reliable -- at
  // least on Chrome, the timeouts still happen even when cleared,
  // if the clear happens after their scheduled firing time).
  var counter = 0;

  function extend(e) {
    var curCount = ++counter;
    var cur = posFromMouse(cm, e, true);
    if (!cur) return;
    if (!posEq(cur, last)) {
      if (!view.focused) onFocus(cm);
      last = cur;
      doSelect(cur);
      var visible = visibleLines(display, doc);
      if (cur.line >= visible.to || cur.line < visible.from)
        setTimeout(operation(cm, function(){if (counter == curCount) extend(e);}), 150);
    } else {
      var outside = e.clientY < editorSize.top ? -20 : e.clientY > editorSize.bottom ? 20 : 0;
      if (outside) setTimeout(operation(cm, function() {
        if (counter != curCount) return;
        display.scroller.scrollTop += outside;
        extend(e);
      }), 50);
    }
  }

  function done(e) {
    counter = Infinity;
    var cur = posFromMouse(cm, e);
    if (cur) doSelect(cur);
    e_preventDefault(e);
    focusInput(cm);
    off(document, "mousemove", move);
    off(document, "mouseup", up);
  }

  var move = operation(cm, function(e) {
    if (!ie && !e_button(e)) done(e);
    else extend(e);
  });
  var up = operation(cm, done);
  on(document, "mousemove", move);
  on(document, "mouseup", up);
}

function onDrop(e) {
  var cm = this;
  if (cm.options.onDragEvent && cm.options.onDragEvent(cm, addStop(e))) return;
  e_preventDefault(e);
  var pos = posFromMouse(cm, e, true), files = e.dataTransfer.files;
  if (!pos || isReadOnly(cm)) return;
  if (files && files.length && window.FileReader && window.File) {
    var n = files.length, text = Array(n), read = 0;
    var loadFile = function(file, i) {
      var reader = new FileReader;
      reader.onload = function() {
        text[i] = reader.result;
        if (++read == n) {
          pos = clipPos(cm.view.doc, pos);
          operation(cm, function() {
            var end = replaceRange(cm, text.join(""), pos, pos, "paste");
            setSelection(cm, pos, end);
          })();
        }
      };
      reader.readAsText(file);
    };
    for (var i = 0; i < n; ++i) loadFile(files[i], i);
  } else {
    // Don't do a replace if the drop happened inside of the selected text.
    if (cm.view.draggingText && !(posLess(pos, cm.view.sel.from) || posLess(cm.view.sel.to, pos))) {
      cm.view.draggingText(e);
      if (ie) setTimeout(bind(focusInput, cm), 50);
      return;
    }
    try {
      var text = e.dataTransfer.getData("Text");
      if (text) {
        var curFrom = cm.view.sel.from, curTo = cm.view.sel.to;
        setSelection(cm, pos, pos);
        if (cm.view.draggingText) replaceRange(cm, "", curFrom, curTo, "paste");
        cm.replaceSelection(text, null, "paste");
        focusInput(cm);
        onFocus(cm);
      }
    }
    catch(e){}
  }
}

function onDragStart(cm, e) {
  var txt = cm.getSelection();
  e.dataTransfer.setData("Text", txt);

  // Use dummy image instead of default browsers image.
  if (e.dataTransfer.setDragImage)
    e.dataTransfer.setDragImage(elt('img'), 0, 0);
}