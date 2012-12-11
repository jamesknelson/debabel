# Debabel Pattern Editor
#
# Authored by James Nelson
# Based on CodeMirror by Marijn Haverbeke

class PatternEditor
  constructor: (@input, o) ->
    @input.style.display = "none"

    # doc.activeElement occasionally throws on IE
    try focused = document.activeElement
    catch focused = document.body

    # Determine effective options based on given values and defaults.
    o ||= {}
    o.value ||= @input.value
    o.tabindex = @input.tabindex if !o.tabindex? and @input.tabindex?
    o.autofocus ?= 
      focused == @input || 
      (@input.getAttribute("autofocus") != null && focused == document.body)

    @options = defaults
    for own key, value of o 
      @options[key] = value
    
    @view =
      frontier: 0 # frontier is the point up to which the content has been parsed
      highlight: new Timer
      sel: {from: 0, to: 0, head: 0, anchor: 0, shift: false, extend: false}
      scrollTop: 0
      overwrite: false
      focused: false
      suppressEdits: false
      goalColumn: null
      cantEdit: false
      keyMaps: []

    this._makeDisplay()
    this._makeHistory()

    @nextOpId = 0

    this._focusInput() if @options.autofocus
    this.setValue(@options.value || "")
    
    # Override magic textarea content restore that IE sometimes does
    # on our hidden textarea on reload
    if ie
      delay 20, => this._resetInput(true)

    this._registerEventHandlers()

    # IE throws unspecified error in certain cases, when
    # trying to access activeElement before onload
    try hasFocus = document.activeElement == display.input
    if hasFocus || @options.autofocus
      delay 20, => this._onFocus()
    else 
      this._onBlur()

    (@operation ->
      for opt in optionHandlers
        if optionHandlers.propertyIsEnumerable opt
          optionHandlers[opt](this, options[opt], Init)
    )()