window.SVGNS = SVGNS = 'http://www.w3.org/2000/svg'

Minus90 = new google.maps.LatLng 0, -90
Plus90  = new google.maps.LatLng 0,  90

RE_MATRIX = /matrix\(.*,\s*(-?\d+),\s*(-?\d+)\)/

class GoogleMapsOverlaySvg extends google.maps.OverlayView
  constructor: (@canvasId, @map, latN, latS, lonW, lonE) ->
    @setMap @map
    @nwBound = new google.maps.LatLng latN, lonW
    @seBound = new google.maps.LatLng latS, lonE

  onAdd: ->
    @div = document.createElement 'div'
    @div.style.border = 'none'
    @div.style.borderWidth = '0px'
    @div.style.position = 'absolute'

    @svg = document.createElementNS SVGNS, 'svg'
    @svg.setAttribute 'version', '1.1'
    @svg.setAttribute 'xmlns', SVGNS

    @div.appendChild @svg
    overlayDiv = @getPanes().overlayLayer
    overlayDiv.appendChild @div
    @dragDiv = overlayDiv.parentNode.parentNode

    canvas = document.getElementById @canvasId
    canvas.onclick = (event) => @click event
    canvas.onmousemove = (event) => @mousemove event
    @

  draw: ->
    @zoom = @map.getZoom()
    proj = @getProjection()
    minus90 = proj.fromLatLngToDivPixel Minus90
    plus90  = proj.fromLatLngToDivPixel Plus90
    @pxEarthW = Math.abs(plus90.x - minus90.x) * 2
    @origin = proj.fromLatLngToDivPixel @nwBound
    se = proj.fromLatLngToDivPixel @seBound
    w = se.x - @origin.x
    w += @pxEarthW if w < 0
    @svg.setAttribute 'width',  "#{w}"
    @svg.setAttribute 'height', "#{se.y - @origin.y}"
    style = @div.style
    style.left = "#{@origin.x}px"
    style.top  = "#{@origin.y}px"
    @

  click: (event) -> @onClick @convertMouseCoord event
  mousemove: (event) -> @onMouseMove @convertMouseCoord event

  onClick: (point) -> # override
  onMouseMove: (point) -> # override

  convertMouseCoord: (event) ->   # returns [point, latLon]
    wkTrans= @dragDiv.style['-webkit-transform']
    if wkTrans? && (re = wkTrans.match RE_MATRIX)?
      dx = parseInt re[1]
      dy = parseInt re[2]
    else
      dx = parseInt @dragDiv.style.left
      dy = parseInt @dragDiv.style.top
    new google.maps.Point event.clientX - dx, event.clientY - dy

window.GoogleMapsOverlaySvg = GoogleMapsOverlaySvg
