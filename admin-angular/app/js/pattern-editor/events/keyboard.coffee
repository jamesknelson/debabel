keyMap = 
  basic:
    Left: "goCharLeft"
    Right: "goCharRight"
    Up: "goLineUp"
    Down: "goLineDown"
    Delete: "delCharAfter"
    Backspace: "delCharBefore"
    Enter: "togglePronunciation"

  # Note that the save and find-related commands aren't defined by
  # default. Unknown commands are simply ignored.
  pcDefault:
    "Ctrl-A": "selectAll", 
    "Ctrl-Z": "undo", 
    "Shift-Ctrl-Z": "redo", "Ctrl-Y": "redo",
    "Ctrl-Home": "goStart", "Alt-Up": "goStart", "Alt-Left": "goStart", 
    "Ctrl-End": "goEnd", "Ctrl-Down": "goEnd", "Alt-Right": "goEnd",

    ## TODO
    "Ctrl-Left": "goWordLeft", "Ctrl-Right": "goWordRight"
    "Ctrl-Backspace": "delWordBefore", "Ctrl-Delete": "delWordAfter", "Ctrl-S": "save", "Ctrl-F": "find",
    "Ctrl-G": "findNext", "Shift-Ctrl-G": "findPrev", "Shift-Ctrl-F": "replace", "Shift-Ctrl-R": "replaceAll",
    "Ctrl-[": "indentLess", "Ctrl-]": "indentMore",
    fallthrough: "basic"

  macDefault:
    ## TODO
    "Cmd-A": "selectAll", "Cmd-D": "deleteLine", "Cmd-Z": "undo", "Shift-Cmd-Z": "redo", "Cmd-Y": "redo",
    "Cmd-Up": "goDocStart", "Cmd-End": "goDocEnd", "Cmd-Down": "goDocEnd", "Alt-Left": "goWordLeft",
    "Alt-Right": "goWordRight", "Cmd-Left": "goLineStart", "Cmd-Right": "goLineEnd", "Alt-Backspace": "delWordBefore",
    "Ctrl-Alt-Backspace": "delWordAfter", "Alt-Delete": "delWordAfter", "Cmd-S": "save", "Cmd-F": "find",
    "Cmd-G": "findNext", "Shift-Cmd-G": "findPrev", "Cmd-Alt-F": "replace", "Shift-Cmd-Alt-F": "replaceAll",
    "Cmd-[": "indentLess", "Cmd-]": "indentMore",
    fallthrough: "basic"

keyMap.default = if mac then keyMap.macDefault else keyMap.pcDefault

keyNames = {3: "Enter", 8: "Backspace", 9: "Tab", 13: "Enter", 16: "Shift", 17: "Ctrl", 18: "Alt",
            19: "Pause", 20: "CapsLock", 27: "Esc", 32: "Space", 33: "PageUp", 34: "PageDown", 35: "End",
            36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 44: "PrintScrn", 45: "Insert",
            46: "Delete", 59: ";", 91: "Mod", 92: "Mod", 93: "Mod", 109: "-", 107: "=", 127: "Delete",
            186: ";", 187: "=", 188: ",", 189: "-", 190: ".", 191: "/", 192: "`", 219: "[", 220: "\\",
            221: "]", 222: "'", 63276: "PageUp", 63277: "PageDown", 63275: "End", 63273: "Home",
            63234: "Left", 63232: "Up", 63235: "Right", 63233: "Down", 63302: "Insert", 63272: "Delete"}

# Number keys
keyNames[i + 48] = String(i) for i in [0..9]
# Alphabetic keys
keyNames[i] = String.fromCharCode(i) for i in [65..90]
# Function keys
keyNames[i + 111] = keyNames[i + 63235] = "F"+i for i in [1..12]

# Returns true if we know what to do with they key, false otherwise
lookupKey = (name, stop, handle) ->
  map = PatternEditor.view.keyMap

  command = map[name]
  if command === false
    stop() if stop
    return true

  return true if command != null and handle(command)

  if map.nofallthrough
    stop() if stop
    return true

  lookupKey(map.fallthrough) or false

isModifierKey = (event) ->
  name = keyNames[e_prop event, "keyCode"]
  name == "Ctrl" or name == "Alt" or name == "Shift" or name == "Mod"


doCommand = (command, dropShift) ->
  return false unless typeof command != "string" or command = commands[command]

  # Ensure previous input has been read, so that the handler sees a
  # consistent view of the document
  # ???
  this.display.pollingFast = false if this.display.pollingFast and this.readInput()

  prevShift = this.view.sel.shift
  try
    this.view.suppressEdits = true if this.isReadOnly()
    this.view.sel.shift = false if dropShift
    command()
  catch e
    throw e if e != Pass
    return false
  this.view.sel.shift = prevShift
  this.view.suppressEdits = false
  return true

handleKeyBinding = (e) ->
  name = keyNames[e_prop e, "keyCode"]
  return false if name == null or e.altGraphKey
  
  flipCtrlCmd = mac and (opera or qtwebkit)
  name = "Alt-"+name if e_prop(e, "altKey")
  name = "Ctrl-"+name if e_prop(e, if flipCtrlCmd then "metaKey" else "ctrlKey")
  name = "Cmd-"+name if e_prop(e, if flipCtrlCmd then "ctrlKey" else "metaKey")

  stopped = false
  stop = -> stopped = true

  handled = if e_prop(e, "shiftKey")
    lookupKey "Shift-"+name, stop, (c) -> doCommand(c, true) or
    lookupKey name, stop, (c) -> doCommand(c) if typeof c == "string" and /^go[A-Z]/.test(c)
  else
    lookupKey name, stop, (c) -> doCommand(c)
  handled = false if stopped

  if handled
    e_preventDefault(e)
    this._restartBlink()
    if ie_lt9
      e.oldKeyCode = e.keyCode
      e.keyCode = 0
  handled

handleCharBinding = (e, ch) ->
  handled = lookupKey "'"+ch+"'", null, (c) -> doCommand c, true
  if handled
    e_preventDefault(e)
    this._restartBlink
  handled

lastStoppedKey = null
onKeyDown = (e) ->
  onFocus() unless this.view.focused
  if ie and e.keyCode == 27
    e.returnValue = false 
  keyCode = e_prop(e, "keyCode")
  # IE does strange things with escape.
  this.view.sel.shift = keyCode == 16 or e_prop(e, "shiftKey")

  handled = handleKeyBinding e

  if opera
    lastStoppedKey = if handled then keyCode else null
    # Opera has no cut event... we try to at least catch the key combo
    if !handled and code == 88 and !hasCopyEvent and e_prop(e, if mac then "metaKey" else "ctrlKey")
      this.replaceSelection("")

onKeyPress = (e) ->
  keyCode = e_prop e, "keyCode"
  charCode = e_prop e, "charCode"

  if opera and keyCode == lastStoppedKey
    lastStoppedKey = null
    e_preventDefault(e)
    return

  return if ((opera and (!e.which or e.which < 10)) or khtml) and handleKeyBinding(e)

  ch = String.fromCharCode(if charCode == null then keyCode else charCode)
  return if handleCharBinding(e, ch)
  this.fastPoll()
