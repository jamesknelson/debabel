# Allow for callback at end
delay = (ms, func) -> setTimeout func, ms

# Self-clearing timer
Timer = -> this.id = null
Timer.prototype.set = (ms, f) ->
  clearTimeout this.id
  this.id = setTimeout f, ms

# Create DOM elements
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

# Allow 3rd-party code to override event properties by adding an override
# object to an event object.
e_prop = (e, prop) ->
  if e.override and e.override.hasOwnProperty(prop)
    e.override[prop]
  else 
    e[prop]

# TODO

function stopMethod() {e_stop(this);}
  // Ensure an event has a stop method.
  function addStop(event) {
    if (!event.stop) event.stop = stopMethod;
    return event;
  }

  function e_preventDefault(e) {
    if (e.preventDefault) e.preventDefault();
    else e.returnValue = false;
  }
  function e_stopPropagation(e) {
    if (e.stopPropagation) e.stopPropagation();
    else e.cancelBubble = true;
  }
  function e_stop(e) {e_preventDefault(e); e_stopPropagation(e);}
  CodeMirror.e_stop = e_stop;
  CodeMirror.e_preventDefault = e_preventDefault;
  CodeMirror.e_stopPropagation = e_stopPropagation;

  function e_target(e) {return e.target || e.srcElement;}
  function e_button(e) {
    var b = e.which;
    if (b == null) {
      if (e.button & 1) b = 1;
      else if (e.button & 2) b = 3;
      else if (e.button & 4) b = 2;
    }
    if (mac && e.ctrlKey && b == 1) b = 3;
    return b;
  }
