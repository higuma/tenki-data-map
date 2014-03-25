round = Math.round

SVGNS = window.SVGNS

### 日本を覆う領域(もし動作不安定になったらこちらに戻す)
NorthBound =  47
SouthBound =  22
WestBound  = 120
EastBound  = 156
###

# 昭和基地まで含めた場合
NorthBound =  47
SouthBound = -71
WestBound  =  39
EastBound  = 156

# render positive number to string with 3 digits
renderSize = (x) ->
  if      x <    1.0 then "#{x}"[0..4]
  else if x >= 100.0 then "#{x >> 0}"
  else                    "#{x}"[0..3]

# scales
dotScale    = Presentation.scale.dot
circleScale = Presentation.scale.circle
windScale   = Presentation.scale.wind
sizeScale   = Presentation.scale.size

# fill/gradient
dotFill     = Presentation.fill.dot.regular
dotFillGray = Presentation.fill.dot.grayed

CIRCLE_GRADIENT =
  t: Presentation.gradient.temp
  p: Presentation.gradient.prec
  s: Presentation.gradient.sun
  f: Presentation.gradient.fall
  d: Presentation.gradient.depth

# wind path
windFill           = Presentation.path.wind.fill
windStroke         = Presentation.path.wind.stroke
windStrokeWidth    = Presentation.path.wind.strokeWidth
windStrokeLineCap  = Presentation.path.wind.strokeLineCap
windStrokeLineJoin = Presentation.path.wind.strokeLineJoin
windPath           = Presentation.path.wind.render

# wind rotation
rotWind = do ->
  rotations = ("rotate(#{i * 22.5})" for i in [0...16])
  rotations.push "rotate(0)"    # for silent
  rotations

# animation interval
animationInterval = Presentation.animation.interval

# data indices
CIRCLE_DATA_INDEX = p:0, t:1, s:4, f:5, d:6
WIND_DATA_INDEX = [2, 3]

RE_DATE = /(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)/

# places info
PLACES = Places

class WeatherView extends GoogleMapsOverlaySvg
  constructor: (canvasId, map, option) ->
    super canvasId, map, NorthBound, SouthBound, WestBound, EastBound
    @ctl = new WeatherController @
    @ctlView = new WeatherControlView @
    t0 = DataInfo.timeMax()     # default (initial) time = last day 12:00
    t0 = t0.prevDay() if t0.hour() < 12
    t0 = Date.YMDH t0.year(), t0.mon(), t0.day(), 12
    @option =
      c: 't'    # circle = t(temp)|p(prec)|s(sun)|f(snowfall)|d(snow depth)
      s: 2      # circle size = 0(none)|1(small)|2(medium)|3(large)
      w: 2      # wind size = 0(none)|1(small)|2(medium)|3(large)
      a: 1      # animation speed = 0(slow)|1(medium)|2(fast)|3(fastest)
      d: t0     # default time
    @processOption option
    return

  processOption: (option) ->
    # merge option to @option and apply settings
    @ctlView.processOption option, @option
    @updateElements() if @svg?
    @ctl.setTime @option.d
    return

  onAdd: ->
    super
    @createElements()
    return

  draw: ->
    super
    @updateElements()
    @updatePopup @popupId if @popupId?
    return

  # <-> controller view
  play: ->
    @ctl.setAnim animationInterval[@option.a]
    return

  stop: ->
    @ctl.setAnim null
    return

  setOption: (key, value) ->
    if @option[key] != value
      @option[key] = value
      if key == 'a'
        @play() if @ctl.interval()?
      else
        @updateElements()
    return

  createElements: ->
    @places = for id, place of PLACES
      @svg.appendChild g = document.createElementNS SVGNS, 'g'

      g.appendChild circle = document.createElementNS SVGNS, 'circle'
      circle.setAttribute 'cx', '0'
      circle.setAttribute 'cy', '0'
      circle.setAttribute 'stroke', 'none'

      g.appendChild wind = document.createElementNS SVGNS, 'path'
      wind.setAttribute 'fill', windFill
      wind.setAttribute 'stroke', windStroke
      wind.setAttribute 'stroke-width', windStrokeWidth
      wind.setAttribute 'stroke-linecap', windStrokeLineCap
      wind.setAttribute 'stroke-linejoin', windStrokeLineJoin

      g.appendChild point = document.createElementNS SVGNS, 'circle'
      point.setAttribute 'cx', '0'
      point.setAttribute 'cy', '0'
      point.setAttribute 'stroke', 'none'

      obj =
        id: id
        g: g
        circle: circle
        wind: wind
        point: point
        lat: place.lat
        lon: place.lon

    return

  updateElements: ->
    proj = @getProjection()
    x0 = @origin.x
    y0 = @origin.y
    pointR = renderSize dotScale[@zoom]
    circleR = renderSize circleScale[@zoom] * sizeScale[@option.s]
    if @zoom < 10
      for place in @places
        pt = new google.maps.LatLng place.lat, place.lon
        c = proj.fromLatLngToDivPixel pt
        c.x += @pxEarthW if c.x < x0
        place.g.setAttribute 'transform',
                             'translate(' + "#{c.x - x0}"[0..6] + ',' +
                             "#{c.y - y0}"[0..6] + ')'
        place.point.setAttribute 'r', pointR
        place.circle.setAttribute 'r', circleR
    else
      for place in @places
        pt = new google.maps.LatLng place.lat, place.lon
        c = proj.fromLatLngToDivPixel pt
        c.x += @pxEarthW if c.x < x0
        place.g.setAttribute 'transform',
                             "translate(#{c.x - x0 >> 0},#{c.y - y0 >> 0})"
        place.point.setAttribute 'r', pointR
        place.circle.setAttribute 'r', circleR
    @updatePoint()
    @updateCircle()
    @updateWind()
    @updateMarker()
    return

  # <- controller

  update: (sender, success) ->
    @ctlView.update success
    if @svg?
      @updatePoint()
      @updateCircle()
      @updateWind()
      @updateMarker()
      @updatePopup @popupId if @popupId?
    return

  updatePoint: ->
    indices = []
    data = @ctl.getData()
    if data?
      indices.push CIRCLE_DATA_INDEX[@option.c] if @option.s > 0
      indices.push WIND_DATA_INDEX[0] if @option.w > 0
    if indices.length == 0
      for place in @places
        place.point.setAttribute 'fill', dotFillGray
    else
      i = j = indices[0]
      j = indices[1] if indices.length == 2
      for place in @places
        d = data[place.id]
        if d && (d[i]? || d[j]?)
          place.point.setAttribute 'fill', dotFill
        else
          place.point.setAttribute 'fill', dotFillGray
    return

  updateCircle: ->
    if @option.s > 0 && (data = @ctl.getData())?
      i = CIRCLE_DATA_INDEX[@option.c]
      g = CIRCLE_GRADIENT[@option.c]
      for place in @places
        d = data[place.id]
        place.circle.setAttribute 'fill', g(if d? then d[i] else null)
    else
      for place in @places
        place.circle.setAttribute 'fill', 'none'
    return

  updateWind: ->
    noPath = windPath null
    if @option.w > 0 && (data = @ctl.getData())?
      scale = renderSize windScale[@zoom] * sizeScale[@option.w]
      scale = "scale(#{scale},#{scale}) "
      [v, r] = WIND_DATA_INDEX
      for place in @places
        wind = place.wind
        d = data[place.id]
        if d? && d[v]? && d[r]?
          wind.setAttribute 'd', windPath(d[v])
          wind.setAttribute 'transform', scale + rotWind[d[r]]
        else
          wind.setAttribute 'd', noPath
    else
      for place in @places
        place.wind.setAttribute 'd', noPath
    return

  updateMarker: ->
    if @markerId?
      place = PLACES[@markerId]
      unless @marker?
        @marker = new google.maps.Marker
          position: new google.maps.LatLng place.lat, place.lon
          map: @getMap()
          title: place.name
      else
        @marker.setMap @getMap()
        @marker.setPosition new google.maps.LatLng place.lat, place.lon
        @marker.setTitle place.name
    else
      @marker.setMap null if @marker?
    return

  onClick: (point) ->
    if (id = @getNearestPlaceId point)?
      @ctlView.showInfo id
      @markerId = id
      @updateMarker()
    return

  onMouseMove: (point) ->
    @updatePopup @getNearestPlaceId point
    return

  getNearestPlaceId: (point) ->
    latLon = @getProjection().fromDivPixelToLatLng point
    lat = latLon.lat()
    lonMap = LatLonMap[round lat / LatLonMap.step]
    return unless lonMap?
    lon = latLon.lng()
    items = lonMap[round lon / LatLonMap.step]
    return unless items?
    placeId = distance = null
    for id in items
      p = PLACES[id]
      dLat = lat - p.lat
      dLon = lon - p.lon
      d = dLat * dLat + dLon * dLon
      if placeId == null || distance > d
        placeId = id
        distance = d
    if placeId?
      p = PLACES[placeId]
      latLon = new google.maps.LatLng p.lat, p.lon
      pt = @getProjection().fromLatLngToDivPixel latLon
      dx = point.x - pt.x
      dy = point.y - pt.y
      placeId = null if dx * dx + dy * dy > 1600    # 40 pixels
    placeId

  updatePopup: (id) ->
    @popupId = id
    if id?
      @popup = new PopupInfoView @div unless @popup?
      @popup.attach()
      place = PLACES[id]
      data = @ctl.getData()[id]
      @popup.setInfo id, place, data
      latLon = new google.maps.LatLng place.lat, place.lon
      xy = @getProjection().fromLatLngToDivPixel latLon
      xy += @pxEarthW if xy.x < @origin.x
      @popup.moveTo xy.x - @origin.x, xy.y - @origin.y
    else if @popup?
      @popup.detach()
    return

  showMarker: (id) ->
    @markerId = id
    @updateMarker()
    return

  onUpdateData: ->
    @ctlView.onUpdateData()
    return

  onHashChange: ->
    option = OptionParser.parseHash()
    @processGoogleMapsOption option
    @processOption option
    return

  processGoogleMapsOption: (option) ->
    opt = OptionParser.processGoogleMapsOption option
    map = @getMap()
    map.setCenter new google.maps.LatLng(opt.lat, opt.lon) if opt.lat?
    map.setZoom opt.zoom if opt.zoom?
    map.setMapTypeId opt.type if opt.type?
    return

window.WeatherView = WeatherView
