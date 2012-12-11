# Based on CodeMirror by Marijn Haverbeke

# IE <= 7 not supported!

# BROWSER SNIFFING
gecko = /gecko\/\d/i.test(navigator.userAgent)
ie = /MSIE \d/.test(navigator.userAgent)
ie_lt8 = /MSIE [1-7]\b/.test(navigator.userAgent)
ie_lt9 = /MSIE [1-8]\b/.test(navigator.userAgent)
webkit = /WebKit\//.test(navigator.userAgent)
qtwebkit = webkit and /Qt\/\d+\.\d+/.test(navigator.userAgent)
chrome = /Chrome\//.test(navigator.userAgent)
opera = /Opera\//.test(navigator.userAgent)
safari = /Apple Computer/.test(navigator.vendor)
khtml = /KHTML\//.test(navigator.userAgent)
mac_geLion = /Mac OS X 1\d\D([7-9]|\d\d)\D/.test(navigator.userAgent)
mac_geMountainLion = /Mac OS X 1\d\D([8-9]|\d\d)\D/.test(navigator.userAgent)
phantom = /PhantomJS/.test(navigator.userAgent)
ios = /AppleWebKit/.test(navigator.userAgent) and /Mobile\/\w+/.test(navigator.userAgent)
mac = ios or /Mac/.test(navigator.platform)

# UTILITIES
delay = (ms, func) -> setTimeout func, ms

Timer = -> this.id = null
Timer.prototype.set = (ms, f) ->
  clearTimeout this.id
  this.id = setTimeout f, ms

make = (tag, classNames, o) ->
  hasClassNames = typeof classNames == "string"
  o ||= (!hasClassNames and classNames) or {}
  e = document.createElement tag
  e.className = classNames if hasClassNames
  setTextContent e, o.text if o.text
  e.appendChild child for child in o.children if o.children
  e.appendChild o.child if o.child
  e.setAttribute attr, val for val, attr of o.attributes if o.attributes
  e

class PatternEditor
  constructor: (@place, options) ->
    @options = defaults

    # Determine effective options based on given values and defaults.
    for own key, value of options 
      @options[key] = value

    this._makeDisplay()
    this._makeView()
    this._makeHistory()

    @nextOpId = 0

    this.focusInput() if @options.autofocus
    
    # @display.wrapper.className += " wrap" if options.lineWrapping

    # Initialize the content.
    # this.setValue options.value || ""
    
    # Override magic textarea content restore that IE sometimes does
    # on our hidden textarea on reload
    if ie
      delay 20, => this.resetInput(true)

    
    this._registerEventHandlers()

    # IE throws unspecified error in certain cases, when
    # trying to access activeElement before onload
    try hasFocus = document.activeElement == display.input
    if hasFocus || options.autofocus
      delay 20, => this._onFocus()
    else 
      this._onBlur()

  _makeDisplay: ->
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
    place.appendChild d.editor

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

  _makeView: ->
    @view =
      doc: doc
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

  _makeHistory: ->
    @history =
      # Arrays of history events. Doing something adds an event to
      # done and clears undo. Undoing moves events from done to
      # undone, redoing moves them in the other direction.
      done: []
      undone: []

      # Used by the isClean() method
      dirtyCounter: 0