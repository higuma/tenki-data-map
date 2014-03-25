SVGNS = window.SVGNS

DIR = DataInfo.WIND_DIRECTION

INFO_TOP = 24
INFO_HEIGHT = 16

class PopupInfoView
  createCaption: (i, text) ->
    $("<span class='popupCaption'>#{text}</span>")
      .css(top: INFO_TOP + i * INFO_HEIGHT)
      .appendTo @div

  createText: (i) ->
    $("<span class='popupValue' />")
      .css(top: INFO_TOP + i * INFO_HEIGHT)
      .appendTo @div

  constructor: (parent) ->
    @parent = $(parent)
    @div = $ "<div class='popupInfo' />"
    @attached = false

    @name = $("<span class='popupPlaceName' />").appendTo @div
    captions = [
      '気温', '降水量', '風速', '風向', '日照時間', '降雪量', '積雪量',
      '緯度', '経度', '標高'
    ]
    vars = ['temp', 'prec', 'vel', 'dir', 'sun', 'fall', 'depth',
            'lat', 'lon', 'alt']
    for i in [0...captions.length]
      @createCaption i, captions[i]
      @[vars[i]] = @createText i
    @attach()

  moveTo: (x, y) ->
    @div.css
      left: x
      top: y
    return

  setInfo: (id, place, data) ->
    @name.empty().append place.name
    if data? && data[1]?
      @temp.empty().append "#{data[1].toFixed(1)} ℃"
    else
      @temp.empty().append "---"
    if data? && data[0]?
      @prec.empty().append "#{data[0].toFixed(1)} mm/時"
    else
      @prec.empty().append "---"
    if data? && data[2]?
      @vel.empty().append "#{data[2].toFixed(1)} m/s"
    else
      @vel.empty().append "---"
    if data? && data[3]?
      @dir.empty().append DIR[data[3]]
    else
      @dir.empty().append "---"
    if data? && data[4]?
      @sun.empty().append "#{data[4].toFixed(1)} 時間"
    else
      @sun.empty().append "---"
    if data? && data[5]?
      @fall.empty().append "#{data[5]} cm"
    else
      @fall.empty().append "---"
    if data? && data[6]?
      @depth.empty().append "#{data[6]} cm"
    else
      @depth.empty().append "---"
    @lat.empty().append place.lat.toFixed 3
    @lon.empty().append place.lon.toFixed 3
    @alt.empty().append "#{place.alt.toFixed if id >= 10000 then 1 else 0} m"
    return

  attach: ->
    unless @attached
      @div.appendTo @parent
      @attached = true
    return

  detach: ->
    if @attached
      @div.detach()
      @attached = false
    return

window.PopupInfoView = PopupInfoView
