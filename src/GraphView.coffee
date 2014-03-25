exp = Math.exp
limitMinMax = MiscUtils.limitMinMax
timeMin = DataInfo.timeMin
timeMax = DataInfo.timeMax

SVGNS = window.SVGNS

HOUR = Date.HOUR
DAY = Date.DAY

PLACES = Places

W_VIEW = Pref.W_GRAPH_VIEW
H_VIEW = Pref.H_GRAPH_VIEW

MARGIN_L = 36
MARGIN_T = 26
MARGIN_R = 18
MARGIN_B = 24

X_GRAPH = MARGIN_L
Y_GRAPH = MARGIN_T
W_GRAPH = W_VIEW - MARGIN_L - MARGIN_R
H_GRAPH = H_VIEW - MARGIN_T - MARGIN_B

XR_GRAPH = X_GRAPH + W_GRAPH
YB_GRAPH = Y_GRAPH + H_GRAPH

X_LABEL_L = X_GRAPH - 4
Y_LABEL_B = Y_GRAPH + H_GRAPH + 7

X_UNIT = X_LABEL_L
Y_UNIT = 12

X_HELP = X_GRAPH + W_GRAPH
Y_HELP = Y_UNIT

W_MSG_BOX = 220
H_MSG_BOX = 50
R_MSG_BOX = 4

X_MESSAGE = X_GRAPH + W_GRAPH / 2
Y_MESSAGE = Y_GRAPH + H_GRAPH / 2

X_MSG_BOX = X_MESSAGE - W_MSG_BOX / 2
Y_MSG_BOX = Y_MESSAGE - H_MSG_BOX / 2

ZOOM_MOUSE_FACTOR = 0.012
ZOOM_WHEEL_FACTOR = 0.1

GRAPH_TYPES = ['t', 'p', 'w', 's', 'f', 'd']

GRAPH_SETTINGS =
  t:
    flag: 4
    name: '気温'
    unit: '(℃)'
    path: 'graphPathT'
    offset: [1, 2]
    defMax: 30
    margin: 4
  p:
    flag: 1
    name: '降水量'
    unit: '(mm)'
    path: 'graphPathP'
    offset: 0
    defMax: 10
  w:
    flag: 2
    name: '風速'
    unit: '(m/s)'
    path: 'graphPathW'
    offset: 3
    defMax: 10
  s:
    flag: 8
    name: '日照時間'
    unit: '(時)'
    path: 'graphPathS'
    offset: 5
    defMax: 1.1
  f:
    flag: 16
    name: '降雪量'
    unit: '(cm)'
    path: 'graphPathF'
    offset: 6
    defMax: 10
  d:
    flag: 16
    name: '積雪量'
    unit: '(cm)'
    path: 'graphPathD'
    offset: 7
    defMax: 40

getTWMin = -> HOUR * 12
getTWMax = -> (timeMax() - timeMin()) * 1.2

LinMap = MiscUtils.LinMap

class GraphView extends GoogleMapsWidget.Element
  constructor: (@infoView) ->
    super 'div'
    @weatherCtl = @infoView.weatherCtl
    @trendCtl = new TrendController @
    @type = 't'     # (t)emp|(p)rec|(w)ind|(s)un|snow(f)all|snow (d)epth
    # @tL and @tR are initially undefined

    @appendChild @svg = svg = document.createElementNS SVGNS, 'svg'
    svg.setAttribute 'class', 'graph'
    svg.setAttribute 'version', '1.1'
    svg.setAttribute 'xmlns', SVGNS
    svg.setAttribute 'width', "#{W_VIEW}"
    svg.setAttribute 'height', "#{H_VIEW}"

    svg.appendChild @unit = unit = document.createElementNS SVGNS, 'text'
    unit.setAttribute 'class', 'graphLabelL'
    unit.setAttribute 'x', "#{X_UNIT}"
    unit.setAttribute 'y', "#{Y_UNIT}"
    unit.appendChild document.createTextNode GRAPH_SETTINGS[@type].name

    svg.appendChild help = document.createElementNS SVGNS, 'text'
    help.setAttribute 'class', 'graphLabelL'
    help.setAttribute 'x', "#{X_HELP}"
    help.setAttribute 'y', "#{Y_HELP}"
    help.appendChild document.createTextNode "横ドラッグ: 時間移動 \xa0 \xa0 \xa0 縦ドラッグ/ホイール: ズーム \xa0"

    svg.appendChild @rect = rect = document.createElementNS SVGNS, 'rect'
    rect.setAttribute 'class', 'graphBG'
    rect.setAttribute 'x', "#{X_GRAPH}"
    rect.setAttribute 'y', "#{Y_GRAPH}"
    rect.setAttribute 'width', "#{W_GRAPH}"
    rect.setAttribute 'height', "#{H_GRAPH}"

    svg.appendChild @gp = document.createElementNS SVGNS, 'g'   # path
    svg.appendChild @gs = document.createElementNS SVGNS, 'g'   # scale+label

    svg.appendChild @marker = marker = document.createElementNS SVGNS, 'line'
    x = "#{X_GRAPH + W_GRAPH/2}"
    marker.setAttribute 'class', 'graphMarker'
    marker.setAttribute 'x1', x
    marker.setAttribute 'x2', x
    marker.setAttribute 'y1', "#{Y_GRAPH}"
    marker.setAttribute 'y2', "#{YB_GRAPH}"

    svg.appendChild pane = document.createElementNS SVGNS, 'rect'
    pane.setAttribute 'class', 'graphMousePane'
    pane.setAttribute 'x', "#{X_GRAPH}"
    pane.setAttribute 'y', "#{Y_GRAPH}"
    pane.setAttribute 'width', "#{W_GRAPH}"
    pane.setAttribute 'height', "#{H_GRAPH}"

    pane = jQuery pane
    pane.mousedown  (event) => @mousedown  event
    pane.mousemove  (event) => @mousemove  event
    pane.mouseup    (event) => @mouseup    event
    pane.mouseout   (event) => @mouseup    event    # same as mouseup
    pane.mousewheel (event) => @mousewheel event

    @gm = gm = document.createElementNS SVGNS, 'g'  # message box + text
    gm.appendChild msgBox = document.createElementNS SVGNS, 'rect'
    msgBox.setAttribute 'class', 'graphMsgBox'
    msgBox.setAttribute 'x', "#{X_MSG_BOX}"
    msgBox.setAttribute 'y', "#{Y_MSG_BOX}"
    msgBox.setAttribute 'width', "#{W_MSG_BOX}"
    msgBox.setAttribute 'height', "#{H_MSG_BOX}"
    msgBox.setAttribute 'rx', "#{R_MSG_BOX}"
    msgBox.setAttribute 'ry', "#{R_MSG_BOX}"

    gm.appendChild @msgText = msgText = document.createElementNS SVGNS, 'text'
    msgText.setAttribute 'class', 'graphMsgText'
    msgText.setAttribute 'x', "#{X_MESSAGE}"
    msgText.setAttribute 'y', "#{Y_MESSAGE}"

    return

  initTimeView: ->
    unless @tL?
      if (t = @weatherCtl.getTime())?
        t = +t.floorDay()       # convert from Date to number
        @tL = t
        @tR = t + Date.DAY
    return @tL

  onSetPlace: ->
    if @initTimeView()?
      @trendCtl.requestData @infoView.id, @tL, @tR, W_GRAPH
    return

  onAttach: (attached) ->
    if (@attached = if attached then true else null)?
      if @tL? && @tR?
        t = +@weatherCtl.getTime()
        unless @tL <= t <= @tR
          dt = (@tR - @tL) / 2
          @tL = t - dt
          @tR = t + dt
      @onSetPlace()
    return

  update: (sender, success) ->
    if success
      if sender == @trendCtl
        iter = @trendCtl.iterator
        @tL = +iter.tL
        @tR = +iter.tR
        @renderGraph iter
      else  # from @weatherCtl
        @initTimeView() # always success
        t = +@weatherCtl.getTime()
        if @tL <= t <= @tR
          @updateMarker()
        else
          dt = (@tR - @tL) / 2
          @trendCtl.requestData @infoView.id, t - dt, t + dt, W_GRAPH
    return

  renderGraph: (iter) ->
    @removeChildren @gp, @gs
    @renderHScale iter
    if @type == 't'
      @renderTemp iter
    else
      @renderValue @type, iter
    @updateMarker()
    @updateMessage iter
    return

  renderTemp: (iter) ->
    setting = GRAPH_SETTINGS.t
    klass = setting.path
    if (minMax = @findTMinMax iter)?
      @showMessage null
      min = minMax[0] - setting.margin
      max = minMax[1] + setting.margin
      @renderVScale min, max
      xmap = new LinMap iter.tL, iter.tR, X_GRAPH, XR_GRAPH
      a = xmap.a
      b = xmap.b
      ymap = new LinMap min, max, YB_GRAPH, Y_GRAPH
      p = ymap.a
      q = ymap.b
      t = iter.reset()
      dt = iter.dt
      path = null
      while t?
        if (d = iter.x)? && (l = d[1])?
          x = if (x = a * t + b) > XR_GRAPH
            "#{XR_GRAPH}"
          else
            "#{x}"[0...6]
          y = "#{p * d[2] + q}"[0...6]
          path = if path?
            "H#{x}V" + "#{p * l + q}"[0...6] + path + "V#{y}H#{x}"
          else
            x0 = X_GRAPH if (x0 = a * (t - dt) + b) < X_GRAPH
            "H#{x}V" + "#{p * l + q}"[0...6] + "H#{x0}V#{y}H#{x}"
        else if path?
          @addPath "M#{x},#{y}#{path}Z", klass
          path = null
        t = iter.next()
      @addPath "M#{x},#{y}#{path}Z", klass if path?
    else
      @renderVScale 0, setting.defMax
    return

  renderValue: (type, iter) ->
    setting = GRAPH_SETTINGS[type]
    i = setting.offset
    minw = setting.defMax
    klass = setting.path
    if (max = @findMax iter, i)?
      max = minw if (max *= 1.05) < minw
      @renderVScale 0, max
      xmap = new LinMap iter.tL, iter.tR, X_GRAPH, X_GRAPH + W_GRAPH
      a = xmap.a
      b = xmap.b
      ymap = new LinMap 0, max, Y_GRAPH + H_GRAPH, Y_GRAPH
      p = ymap.a
      q = ymap.b
      t = iter.reset()
      dt = iter.dt
      y0 = "#{YB_GRAPH}"
      path = null
      while t?
        if (d = iter.x)? && (v = d[i])?
          unless path?
            x0 = X_GRAPH if (x0 = a * (t - dt) + b) < X_GRAPH
            path = 'M' + "#{x0}"[0...6] + ",#{y0}"
          x = XR_GRAPH if (x = a * t + b) > XR_GRAPH
          path += 'V' + "#{p * v + q}"[0...6] + 'H' + "#{x}"[0...6]
        else if path?
          @addPath "#{path}V#{y0}Z", klass
          path = null
        t = iter.next()
      @addPath "#{path}V#{y0}Z", klass if path?
    else
      @renderVScale 0, minw
    return

  renderHScale: (iter) ->
    tL = +iter.tL
    tR = +iter.tR
    sc = TimeScaleIterator iter.tL, iter.tR, W_GRAPH
    t = sc.reset()
    map = new LinMap tL, tR, X_GRAPH, X_GRAPH + W_GRAPH
    a = map.a
    b = map.b
    y1 = "#{Y_GRAPH}"
    y2 = "#{YB_GRAPH}"
    ys = "#{Y_LABEL_B}"
    while t?
      @gs.appendChild s = document.createElementNS SVGNS, 'line'
      s.setAttribute 'class', if sc.s? then 'graphScale' else 'graphSubscale'
      x = "#{a * t + b}"[0...6]
      s.setAttribute 'x1', x
      s.setAttribute 'x2', x
      s.setAttribute 'y1', y1
      s.setAttribute 'y2', y2
      if sc.s? && sc.s.length > 0
        @gs.appendChild l = document.createElementNS SVGNS, 'text'
        l.setAttribute 'class', 'graphLabelB'
        l.setAttribute 'x', x
        l.setAttribute 'y', ys
        l.appendChild document.createTextNode sc.s
      t = sc.next()
    return

  renderVScale: (min, max) ->
    x1 = "#{X_GRAPH}"
    xs = "#{X_LABEL_L}"
    x2 = "#{XR_GRAPH}"
    map = new LinMap min, max, Y_GRAPH + H_GRAPH, Y_GRAPH
    a = map.a
    b = map.b
    sc = new ValueScaleIterator min, max, H_GRAPH
    v = sc.reset()
    while v?
      @gs.appendChild s = document.createElementNS SVGNS, 'line'
      s.setAttribute 'class', if sc.s? then 'graphScale' else 'graphSubscale'
      y = "#{a * v + b}"[0...6]
      s.setAttribute 'x1', x1
      s.setAttribute 'x2', x2
      s.setAttribute 'y1', y
      s.setAttribute 'y2', y
      if sc.s?
        @gs.appendChild l = document.createElementNS SVGNS, 'text'
        l.setAttribute 'class', 'graphLabelL'
        l.setAttribute 'x', xs
        l.setAttribute 'y', y
        l.appendChild document.createTextNode sc.s
      v = sc.next()
    return

  updateMarker: ->
    t = +@weatherCtl.getTime()
    marker = @marker
    if @tL <= t <= @tR
      x = "#{X_GRAPH + W_GRAPH * (t - @tL) / (@tR - @tL)}"[0...6]
      marker.setAttribute 'x1', x
      marker.setAttribute 'x2', x
      marker.setAttribute 'class', 'graphMarker'
    else
      marker.setAttribute 'class', 'graphHidden'
    return

  updateMessage: (iter) ->
    place = PLACES[iter.id]
    setting = GRAPH_SETTINGS[@type]
    if (place.flags & setting.flag) != 0
      @showMessage null
    else
      @showMessage setting.name + 'のデータはありません'
    return

  setTimeView: (tL, tR) ->
    if tL < tR
      wt = limitMinMax tR - tL, getTWMin(), getTWMax()
      tm = wt / 2
      if tL < (t = +timeMin() - tm)
        tL = t
        tR = tL + wt
      else if tR > (t = +timeMax() + tm)
        tR = t
        tL = tR - wt
      @trendCtl.requestData @infoView.id, tL, tR, W_GRAPH if @attached?
    return

  mousedown: (event) ->
    event.preventDefault()
    if @tL? && @tR?
      @shift = event.shiftKey
      @ctrl = event.ctrlKey
      r = @rect.getBoundingClientRect()
      @x = event.clientX - r.left
      @y = event.clientY - r.top
      @w = @tR - @tL
      @t = if shift?
        @t = @tL + @x * @w / W_GRAPH
      else
        @t = @tL + @x * @w / W_GRAPH
      @weatherCtl.setTime @t unless @shift || @ctrl
    return

  mousemove: (event) ->
    event.preventDefault()
    if @x?
      r = @rect.getBoundingClientRect()
      x = if @ctrl then @x else event.clientX - r.left
      y = event.clientY - r.top
      w = if @shift then @w else @w * exp(ZOOM_MOUSE_FACTOR * (y - @y))
      if w < (twMin = getTWMin())
        w = twMin
      else if w > (twMax = getTWMax())
        w = twMax
      @setTimeView @t - w * x / W_GRAPH, @t + w * (W_GRAPH - x) / W_GRAPH
    return

  mouseup: (event) ->
    @x = @y = @w = @t = null
    return

  mousewheel: (event) ->
    event.preventDefault()
    if @tL? && @tR?
      x = event.clientX - @rect.getBoundingClientRect().left
      t = @tL + (@tR - @tL) * x / W_GRAPH
      scale = exp -ZOOM_WHEEL_FACTOR * event.deltaY
      l = t - (t - @tL) * scale
      r = t + (@tR - t) * scale
      if r - l < (twMin = getTWMin())
        l = t - twMin * (t - @tL) / (@tR - @tL)
        r = l + twMin
      else if r - l > (twMax = getTWMax())
        l = t - twMax * (t - @tL) / (@tR - @tL)
        r = l + twMax
      @setTimeView l, r
    return

  findMax: (iter, i) ->
    t = iter.reset()
    max = null
    while t?
      if (x = iter.x)? && (y = x[i])?
        max = y
        break
      t = iter.next()
    if max?
      while iter.next()?
        max = y if (x = iter.x)? && (y = x[i])? && y > max
    max

  findTMinMax: (iter) ->
    t = iter.reset()
    min = max = null
    while t?
      if (x = iter.x)? && (y = x[1])?
        min = y
        max = x[2]
        break
      t = iter.next()
    if min?
      while iter.next()?
        if (x = iter.x)? && (y = x[1])?
          min = y if y < min
          max = y if (y = x[2]) > max
      [min, max]

  addPath: (path, klass) ->
    @gp.appendChild p = document.createElementNS SVGNS, 'path'
    p.setAttribute 'class', klass
    p.setAttribute 'd', path
    return

  setGraph: (type) ->
    if GRAPH_TYPES.indexOf(type) != -1
      @type = type
      @removeChildren @unit
      @unit.appendChild document.createTextNode GRAPH_SETTINGS[@type].unit
      @update @trendCtl, true if @trendCtl.iterator?
    return

  showMessage: (msg) ->
    if msg?
      @svg.appendChild @gm unless @gm.parentNode?
      @removeChildren @msgText
      @msgText.appendChild document.createTextNode msg
    else
      @svg.removeChild @gm if @gm.parentNode?
    return

  removeChildren: (elems...) ->
    MiscUtils.removeChildren e for e in elems
    return

window.GraphView = GraphView
