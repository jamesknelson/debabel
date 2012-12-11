class PatternEditor
  makeHistory: ->
    @history =
      # Arrays of history events. Doing something adds an event to
      # done and clears undo. Undoing moves events from done to
      # undone, redoing moves them in the other direction.
      done: []
      undone: []

      # Used by the isClean() method
      dirtyCounter: 0

  addHistory: (start, added, old, origin, fromBefore, toBefore, fromAfter, toAfter) ->
    time = +new Date # + converts to an integer

    @history.undone.length = 0
    @history.done.push start: start, added: added, old: old, fromBefore: fromBefore, toBefore: toBefore, fromAfter: fromAfter, toAfter: toAfter
    while @history.done.length > @options.undoDepth
      @history.done.shift()

      # ???
      if @history.dirtyCounter < 0
          # The user has made a change after undoing past the last clean state. 
          # We can never get back to a clean state now until markClean() is called.
          @history.dirtyCounter = NaN
      else
        @history.dirtyCounter++

  travelHistory: (type) ->
    set = (if type == "undo" then hist.done else hist.undone).pop()
    return unless set
    
## TODO
    var anti = {events: [], fromBefore: set.fromAfter, toBefore: set.toAfter,
                fromAfter: set.fromBefore, toAfter: set.toBefore};
    for (var i = set.events.length - 1; i >= 0; i -= 1) {
      hist.dirtyCounter += type == "undo" ? -1 : 1;
      var change = set.events[i];
      var replaced = [], end = change.start + change.added;
      doc.iter(change.start, end, function(line) { replaced.push(newHL(line.text, line.markedSpans)); });
      anti.events.push({start: change.start, added: change.old.length, old: replaced});
      var selPos = i ? null : {from: set.fromBefore, to: set.toBefore};
      updateDocNoUndo(cm, {line: change.start, ch: 0}, {line: end - 1, ch: getLine(doc, end-1).text.length},
                      change.old, selPos, type);
    }
    (type == "undo" ? hist.undone : hist.done).push(anti);
  }