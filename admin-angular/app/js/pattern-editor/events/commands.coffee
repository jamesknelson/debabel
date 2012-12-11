commands =
  selectAll: -> this.setSelection 0, this.patternLength()-1
  undo: -> this.undo()
  redo: -> this.redo()
  goStart: -> this.extendSelection 0
  goEnd: -> this.extendSelection this.patternLength()-1
  goCharLeft: -> this.moveH -1, "char"
  goCharRight: -> this.moveH 1, "char"
  goColumnLeft: -> this.moveH -1, "column"
  goColumnRight: -> this.moveH 1, "column"
  goWordLeft: -> this.moveH -1, "word"
  goWordRight: -> this.moveH 1, "word"
  delCharBefore: -> this.deleteH -1, "char"
  delCharAfter: -> this.deleteH 1, "char"
  delWordBefore: -> this.deleteH -1, "word"
  delWordAfter: -> this.deleteH 1, "word"