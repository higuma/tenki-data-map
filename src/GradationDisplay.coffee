log = Math.log
LN_10 = 1.0 / Math.LN10

scaleStep = (w) ->
  log10 = log(w) * LN_10
  e10 = Math.floor log10
  p10 = Math.pow 10, e10
  r = w / p10           # [1, 10)
  step = p10 * if r < 1.2
    0.2
  else if r < 3
    0.5
  else if r < 5
    1
  else
    2

fracDigits = (step) ->
  log10 = log(step) * LN_10
  if log10 >= 0
    0
  else
    Math.ceil(-log10)

SVGNS = window.SVGNS

W_GRAD = Pref.W_GRADATION_DISPLAY
MARGIN = 10
W_GRADFRAME = W_GRAD + 2 * MARGIN

W_WIND = 80
W_WINDFRAME = W_WIND + 2 * MARGIN

Y_TEXT =  7
Y_LINE = 11
H_LINE = -2     # draw upward
Y_GRAD = Y_LINE + 3
H_GRAD = 8
H_GRADFRAME = Y_GRAD + H_GRAD

H_WINDFRAME = H_GRADFRAME

RE_SVGA_ALPHA = /rgba\((\d+,\s*\d+,\s*\d+),\s*(.+)\)/

class ScaleDisplay
  constructor: (@width, @height, @margin, @x0, @x1, @dxScale) ->
    @svg = @createElem('svg')
      .attr version: '1.1', xmlns: SVGNS, width: @width, height: @height
    @createScale()

  createElem: (elem) -> $ document.createElementNS SVGNS, elem

  getSvg: -> @svg

  createScale: ->
    @gScale = @createElem('g')
      .attr
        stroke: 'rgba(0, 0, 0, 0.75)'
        'stroke-width': 1
        'stroke-linecap': 'square'
        'shape-rendering': 'crispEdges'
      .appendTo @svg
    @gText = @createElem('g')
      .attr
        'font-family': 'Arial, sans-serif'
        'font-size': '9px'
        'text-anchor': 'middle'
      .appendTo @svg

  drawScale: ->
    @createElem('line')
      .attr
        x1: @margin
        y1: Y_LINE
        x2: @width - @margin
        y2: Y_LINE
      .appendTo @gScale

    x = @x0
    gx = @margin
    gxdx = 1.0 * (@width - 2 * @margin) / (@x1 - @x0)
    f = fracDigits @dxScale
    while x <= @x1
      gx = @margin + gxdx * (x - @x0)
      @createElem('line')
        .attr
          x1: gx
          y1: Y_LINE
          x2: gx
          y2: Y_LINE + H_LINE
        .appendTo @gScale
      @createElem('text')
        .attr
          x: gx
          y: Y_TEXT
        .append(x.toFixed f)
        .appendTo @gText
      x += @dxScale

class GradientDisplay extends ScaleDisplay
  constructor: (x0, x1, dxScale, @dxGrad, @gradId, @gradFunc) ->
    super W_GRADFRAME, H_GRADFRAME, MARGIN, x0, x1, dxScale
    @createGradient()
    @createDisplay()
    @drawScale()

  parseRGBA: (rgba) ->
    re = rgba.match RE_SVGA_ALPHA
    if re?
      ["rgb(#{re[1]})", re[2]]
    else
      [rgba, rgba]

  createGradient: ->
    grad = @createElem('linearGradient')
      .attr(id: @gradId)
      .appendTo @svg
    x = @x0
    while x <= @x1
      [rgb, alpha] = @parseRGBA @gradFunc x
      @createElem('stop')
        .attr
          offset: "#{100.0 * (x - @x0) / (@x1 - @x0)}%"
          'stop-color': rgb
          'stop-opacity': alpha
        .appendTo grad
      x += @dxGrad

  createDisplay: ->
    @createElem('rect')
      .attr
        x: @margin
        y: Y_GRAD
        width: @width - 2 * @margin
        height: H_GRAD
        fill: "url(\##{@gradId})"
      .appendTo @svg

class DisplayFrame
  constructor: (@parent, @width, @height) ->
    @frame = $("<div id='tenkiGradation'/>")
      .css
        width: "#{@width}px"
        height: "#{@height}px"
      .appendTo @parent

  setDisplay: (display) ->
    @frame.empty()
    @frame.append display.getSvg() if display?

GRADIENT = Presentation.gradient

class GradationDisplay
  constructor: (parent, dataView) ->
    parent = $ parent
    @row = $('<div />').appendTo parent

    @gradFrame = new DisplayFrame @row, W_GRADFRAME, H_GRADFRAME
    # @windFrame = new DisplayFrame @row, W_WINDFRAME, H_WINDFRAME

    @temp = new GradientDisplay -30, 40, 10, 1, 'SvgTempGrad', GRADIENT.temp
    @prec = new GradientDisplay 0, 100, 20, 1, 'SvgPrecGrad', GRADIENT.prec
    @sun = new GradientDisplay 0, 1, 0.2, 0.1, 'SvgPrecSun', GRADIENT.sun
    @fall = new GradientDisplay 0, 20, 5, 1, 'SvgPrecFall', GRADIENT.fall
    @depth = new GradientDisplay 0, 300, 50, 1, 'SvgPrecDepth', GRADIENT.depth

  setGrad: (type) ->
    @gradFrame.setDisplay switch type
      when 't' then @temp
      when 'p' then @prec
      when 's' then @sun
      when 'f' then @fall
      when 'd' then @depth
      else          null

window.GradationDisplay= GradationDisplay
