# CSS interface: class names
CLASS_FRAME = 'gmw-frame'
CLASS_ROW = 'gmw-row'
CLASS_SUBFRAME = 'gmw-subframe'
CLASS_SUBROW = 'gmw-subrow'
CLASS_HR = 'gmw-hr'

CLASS_SPACER_PREFIX = 'gmw-spacer-'

CLASS_TEXT = 'gmw-text'

CLASS_STATIC =
  normal: 'gmw-static-n'
  grayed: 'gmw-static-g'

CLASS_BUTTON =
  regular:
    normal: 'gmw-button-r-n'
    grayed: 'gmw-button-r-g'
    pressed: 'gmw-button-r-p'
  highlight:
    normal: 'gmw-button-h-n'
    grayed: 'gmw-button-h-g'
    pressed: 'gmw-button-h-p'

CLASS_RADIO =
  left:
    regular:
      normal: 'gmw-radio-l-r-n'
      grayed: 'gmw-radio-l-r-g'
      pressed: 'gmw-radio-l-r-p'
    highlight:
      normal: 'gmw-radio-l-h-n'
      grayed: 'gmw-radio-l-h-g'
      pressed: 'gmw-radio-l-h-p'
  middle:
    regular:
      normal: 'gmw-radio-m-r-n'
      grayed: 'gmw-radio-m-r-g'
      pressed: 'gmw-radio-m-r-p'
    highlight:
      normal: 'gmw-radio-m-h-n'
      grayed: 'gmw-radio-m-h-g'
      pressed: 'gmw-radio-m-h-p'
  right:
    regular:
      normal: 'gmw-radio-r-r-n'
      grayed: 'gmw-radio-r-r-g'
      pressed: 'gmw-radio-r-r-p'
    highlight:
      normal: 'gmw-radio-r-h-n'
      grayed: 'gmw-radio-r-h-g'
      pressed: 'gmw-radio-r-h-p'

CLASS_SELECT = 'gmw-select'

CLASS_TABLE = 'gmw-table'
CLASS_TBODY = 'gmw-tbody'
CLASS_TR = 'gmw-tr'
CLASS_TH = 'gmw-th'
CLASS_TD =
  left:
    regular: 'gmw-tdl'
    highlight: 'gmw-tdl-h'
  center:
    regular: 'gmw-tdc'
    highlight: 'gmw-tdc-h'
  right:
    regular: 'gmw-tdr'
    highlight: 'gmw-tdr-h'

# element
class Element
  constructor: (tag, parent, klass) ->
    @elem = document.createElement tag
    parent.appendChild @elem if parent?
    @setClass klass if klass?
    @bounds = {}
    @

  getElement: -> @elem

  appendChild: (elem) ->
    elem = elem.getElement() if elem instanceof Element
    @elem.appendChild elem
    @

  removeChild: (elem) ->
    elem = elem.getElement() if elem instanceof Element
    @elem.removeChild elem
    @

  replaceChild: (rem, add) ->
    rem = rem.getElement() if rem instanceof Element
    add = add.getElement() if add instanceof Element
    @elem.replaceChild rem, add
    @

  setClass: (klass) ->
    @elem.className = klass if klass?
    @

  addClass: (klass) ->
    classes = @elem.className.split ' '
    if classes.indexOf(klass) == -1
      classes.push klass
      @elem.className = classes.join ' '
    @

  removeClass: (klass) ->
    classes = @elem.className.split ' '
    if (i = classes.indexOf klass) != -1
      classes.splice i, 1
      @elem.className = classes.join ' '
    @

  setText: (text) ->
    @elem.innerHTML = text if text?
    @

  setTitle: (title) ->
    @elem.title = title if title?
    @

  bind: (event, handler) ->
    unless @bounds[event]
      @bounds[event] = google.maps.event.addDomListener @elem, event, handler
    @

  unbind: (event) ->
    if @bounds[event]
      google.maps.event.removeListener @bounds[event]
      delete @bounds[event]
    @

# spacer
class Spacer extends Element
  constructor: (parent, width) ->
    super 'span', parent, CLASS_SPACER_PREFIX + width

# widget element
class Widget extends Element
  constructor: (parent, klass) ->
    super 'span', parent, klass
    @stat = 'normal'    # normal|grayed|pressed
    @

  state: -> @stat

  setState: (stat) ->
    @stat = stat
    @setClass @stateToClass()[@stat]    # subclass must implement stateToClass
    @

# static text (normal)
class Text extends Element
  constructor: (parent, text) ->
    super 'span', parent, CLASS_TEXT
    @setText text

# static text (display)
class Static extends Widget
  constructor: (parent, text) ->
    super
    @setText text
    @setState 'normal'
    @

  stateToClass: -> CLASS_STATIC

# button
class Button extends Widget
  constructor: (parent, text, title, @onClick) ->
    @hi = 'regular'     # regular|highlight
    super
    @elem.draggable = false
    @setText text
    @setTitle title
    @enable true
    @

  highlight: -> @hi

  setHighlight: (@hi) ->
    @setState @stat
    @

  stateToClass: -> CLASS_BUTTON[@hi]

  enable: (onOff) ->
    if onOff
      @bind 'mousedown', (event) => @mousedown event
      @bind 'mouseout', (event) => @mouseout event
      @bind 'click', (event) => @click event
      @setState 'normal'
    else
      @unbind 'mousedown'
      @unbind 'mouseout'
      @unbind 'click'
      @setState 'grayed'
    @

  mousedown: (event) ->
    @setState 'pressed'

  mouseout: (event) ->
    @setState 'normal'

  click: (event) ->
    @setState 'normal'
    @onClick(@) if @onClick?

# radio buttons
class RadioButton extends Button
  constructor: (parent, text, title, onClick) ->
    @style = 'middle'   # left|moddle|right
    super

  setStyle: (@style) -> @

  stateToClass: -> CLASS_RADIO[@style][@hi]

class RadioGroup
  constructor: (@parent, @handler) ->
    @buttons = []
    @sel = null
    @

  bind: (@handler) ->

  add: (text, title) ->
    title = text unless title?
    button = new RadioButton @parent, text, title, (b) => @click(b)
    button.index = @buttons.length
    @buttons.push button
    @

  finalize: (sel = 0) ->
    throw 'RadioGroup: at least 2 buttons needed' if @buttons.length < 2
    @buttons[0].setStyle 'left'
    @buttons[@buttons.length - 1].setStyle 'right'
    @select sel
    @

  click: (b) ->
    @select b.index
    @handler b.index if @handler

  selected: -> @sel

  select: (sel) ->
    @sel = sel
    @update()

  update: ->
    for i in [0...@buttons.length]
      @buttons[i].setHighlight(if i == @sel then 'highlight' else 'regular')
    @

  enable: (ena) ->
    for button in @buttons
      button.enable ena
    @

# select/option
class Option extends Element
  constructor: (parent, text, value) ->
    super 'option', parent
    @setText text
    @elem.value = value.toString()
    @

class Select extends Element
  constructor: (parent, handler) ->
    super 'select', parent, CLASS_SELECT
    @bind 'change', handler if handler

  options: -> @elem.children
  length: -> @elem.children.length

  clear: -> @elem.innerHTML = ''; @
  add: (text, value) -> new Option @, text, value; @

  select: (value) ->
    value = value.toString()
    iSel = -1
    for i in [0...@elem.children.length]
      if @elem.children[i].value == value
        iSel = i
        break
    @elem.selectedIndex = iSel if iSel != -1
    @

  enable: (onOff) ->
    @elem.disabled = !onOff
    @

  value: (index = null) ->
    index = @elem.selectedIndex unless index?
    @elem.children[index].value

#table elements
class TH extends Element
  constructor: (parent, text) ->
    super 'th', parent, CLASS_TH
    @setText text if text?

class TD extends Element
  constructor: (parent, text, @align = 'left') ->
    @hi = 'regular'
    super 'td', parent, CLASS_TD[@align][@hi]
    @setText text if text?

  highlight: -> @hi

  setHighlight: (@hi) -> @setClass CLASS_TD[@align][@hi]

class TR extends Element
  constructor: (parent) ->
    super 'tr', parent, CLASS_TR

  addTH: (text) -> new TH @, text
  addTD: (text, align) -> new TD @, text, align
  addTDL: (text) -> new TD @, text, 'left'
  addTDC: (text) -> new TD @, text, 'center'
  addTDR: (text) -> new TD @, text, 'right'

class TBody extends Element
  constructor: (parent) -> super 'tbody', parent, CLASS_TBODY

  addTR: -> tr = new TR @

class Table extends Element
  constructor: (parent) ->
    super 'table', parent, CLASS_TABLE
    @tbody = new TBody @

  addTR: -> @tbody.addTR()

# block elements (frame and row)
class Row extends Element
  constructor: (parent) ->
    super 'div', parent, CLASS_ROW

  addSpacer: (width) -> new Spacer @, width
  addText: (text) -> new Text @, text
  addStatic: (text) -> new Static @, text
  addButton: (text, title, onClick) -> new Button @, text, title, onClick
  addRadioGroup: (handler) -> new RadioGroup @, handler
  addSelect: (handler) -> new Select @, handler

class Subrow extends Row
  constructor: (parent) ->
    super
    @setClass CLASS_SUBROW

class HR extends Element
  constructor: (parent) ->
    super 'div', parent, CLASS_HR

class Subframe extends Element
  constructor: (parent) ->
    super 'div', parent, CLASS_SUBFRAME

  addRow: -> new Subrow @
  addHR: -> new HR @
  addSubframe: -> new Subframe @

class Frame extends Subframe
  constructor: ->
    super null
    @setClass CLASS_FRAME
    @bind 'click', (event) -> event.stopPropagation()
    @bind 'mousemove', (event) -> event.stopPropagation()

  addRow: -> new Row @

window.GoogleMapsWidget =
  Element: Element
  Spacer: Spacer
  Widget: Widget
  Static: Static
  Text: Text
  Button: Button
  RadioButton: RadioButton
  RadioGroup: RadioGroup
  Select: Select
  Table: Table
  TBody: TBody
  TR: TR
  TH: TH
  TD: TD
  Row: Row
  Subrow: Subrow
  HR: HR
  Subframe: Subframe
  Frame: Frame
