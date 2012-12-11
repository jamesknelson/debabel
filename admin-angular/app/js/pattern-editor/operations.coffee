# Operations are used to wrap changes in such a way that each
# change won't have to update the cursor and display (which would
# be awkward, slow, and error-prone), but instead updates are
# batched and then all combined and executed at once.

class PatternEditor
  operation: (f) ->
    return function() {
      var pe = cm1 || this;
      startOperation(cm);
      try {var result = f.apply(cm, arguments);}
      finally {endOperation(cm);}
      return result;
    };
}

  function startOperation(cm) {
    if (cm.curOp) ++cm.curOp.depth;
    else cm.curOp = {
      // Nested operations delay update until the outermost one
      // finishes.
      depth: 1,
      // An array of ranges of lines that have to be updated. See
      // updateDisplay.
      changes: [],
      delayedCallbacks: [],
      updateInput: null,
      userSelChange: null,
      textChanged: null,
      selectionChanged: false,
      updateMaxLine: false,
      id: ++cm.nextOpId
    };
  }

  function endOperation(cm) {
    var op = cm.curOp;
    if (--op.depth) return;
    cm.curOp = null;
    var view = cm.view, display = cm.display;
    if (op.updateMaxLine) computeMaxLength(view);
    if (view.maxLineChanged && !cm.options.lineWrapping) {
      var width = measureChar(cm, view.maxLine, view.maxLine.text.length).right;
      display.sizer.style.minWidth = (width + 3 + scrollerCutOff) + "px";
      view.maxLineChanged = false;
    }
    var newScrollPos, updated;
    if (op.selectionChanged) {
      var coords = cursorCoords(cm, view.sel.head);
      newScrollPos = calculateScrollPos(cm, coords.left, coords.top, coords.left, coords.bottom);
    }
    if (op.changes.length || newScrollPos && newScrollPos.scrollTop != null)
      updated = updateDisplay(cm, op.changes, newScrollPos && newScrollPos.scrollTop);
    if (!updated && op.selectionChanged) updateSelection(cm);
    if (newScrollPos) scrollCursorIntoView(cm);
    if (op.selectionChanged) restartBlink(cm);

    if (view.focused && op.updateInput)
      resetInput(cm, op.userSelChange);

    if (op.textChanged)
      signal(cm, "change", cm, op.textChanged);
    if (op.selectionChanged) signal(cm, "cursorActivity", cm);
    for (var i = 0; i < op.delayedCallbacks.length; ++i) op.delayedCallbacks[i](cm);
  }

  # Wraps a function in an operation. Returns the wrapped function.
  

  function regChange(cm, from, to, lendiff) {
    cm.curOp.changes.push({from: from, to: to, diff: lendiff});
  }