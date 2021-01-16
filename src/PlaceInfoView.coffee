PLACES = Places
NULL = '---'

RE_NAME = /^(.+) - (.+)$/

LAT_PREFIX = ['北緯', '南緯']
LON_PREFIX = ['東経', '西経']

class PlaceInfoView extends GoogleMapsWidget.Table
  constructor: (@infoView) ->
    super null      # do not append to parent view
    tr = @addTR()
    tr.addTH '地域'
    @pref = tr.addTDL NULL
    tr = @addTR()
    tr.addTH '地名'
    @name = tr.addTDL NULL
    tr = @addTR()
    tr.addTH '緯度'
    @lat = tr.addTDL NULL
    tr = @addTR()
    tr.addTH '経度'
    @lon = tr.addTDL NULL
    tr = @addTR()
    tr.addTH '標高'
    @alt = tr.addTDL NULL
    tr = @addTR()
    tr.addTH '観測量'
    @obs = tr.addTDL NULL

  refresh: ->
    id = @infoView.id
    if (p = PLACES[id])?
      re = p.name.match RE_NAME
      @pref.setText re[1]
      @name.setText "#{re[2]} (#{p.kana})"
      x = @numberToDegMinSec p.lat
      y = @numberToDegMinSec p.lon
      @lat.setText "#{LAT_PREFIX[x[0]]}#{x[1]}度#{x[2]}分#{x[3]}秒"
      @lon.setText "#{LON_PREFIX[y[0]]}#{y[1]}度#{y[2]}分#{y[3]}秒"
      @alt.setText "#{p.alt.toFixed if id >= 10000 then 1 else 0}m"
      @obs.setText @observingValues(p.flags)
    else
      @pref.setText NULL
      @name.setText NULL
      @lat.setText NULL
      @lon.setText NULL
      @alt.setText NULL
      @obs.setText NULL
    return

  numberToDegMinSec: (x) ->
    s = Math.round(3600 * Math.abs(x))
    [Number(x < 0), s / 3600 >> 0, (s / 60 >> 0) % 60, s % 60]

  observingValues: (flags) ->
    s = []
    s.push '気温' if (flags & 4) != 0
    s.push '降水量' if (flags & 1) != 0
    s.push '風速・風向' if (flags & 2) != 0
    s.push '日照時間' if (flags & 8) != 0
    s.push '降雪・積雪' if (flags & 16) != 0
    s.join ', '

  onAttach: (attached) -> @refresh() if attached
  update: (sender, success) -> @refresh() if success
  onSetPlace: -> @refresh()

window.PlaceInfoView = PlaceInfoView
