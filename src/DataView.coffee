HOUR = Date.HOUR

HEADERS = [
  "時刻<br />(時)"
  "気温<br />(℃)"
  "降水量<br />(mm)"
  "風速<br />(m/s)"
  "風向"
  "日照時間<br />(時)"
  "降雪量<br />(cm)"
  "積雪量<br />(cm)"
]

DIR = DataInfo.WIND_DIRECTION

NULL = '---'

class TDData extends GoogleMapsWidget.TD
  constructor: (tr, align, @view, @hour) ->
    super tr, NULL, align
    @bind 'mousedown', (event) => @mousedown event

  mousedown: (event) ->
    @view.clickOnTable @hour

class DataView extends GoogleMapsWidget.Table
  constructor: (@infoView) ->
    super null          # do not append to parent
    @weatherCtl = @infoView.weatherCtl
    @trendCtl = new TrendController @
    tr = @addTR()
    for hdr in HEADERS
      tr.addTH hdr
    @items = for i in [0...24]
      tr = @addTR()
      [ new TDData tr, 'right',  @, i   # hour
        new TDData tr, 'right',  @, i   # temperature
        new TDData tr, 'right',  @, i   # precipitation
        new TDData tr, 'right',  @, i   # wind velocity
        new TDData tr, 'center', @, i   # wind direction
        new TDData tr, 'right',  @, i   # sunlight
        new TDData tr, 'right',  @, i   # snowfall
        new TDData tr, 'right',  @, i   # snow depth
      ]
    @id = @t0 = @now = null # @id,@t0 for updateTable, @now for updateNow

  onSetPlace: ->
    if (t = @weatherCtl.getTime())?
      t = t.floorDay()
      @trendCtl.requestData @infoView.id, t, t.nextHour(23), 24
    return

  onAttach: (toAttach) ->
    @onSetPlace() if toAttach
    return

  update: (sender, success) ->
    if success
      if sender == @weatherCtl
        @updateTime @weatherCtl.getTime()
      else # @trendCtl
        if (iter = sender.iterator)? && iter.hasData?
          @updateTable iter
        else
          @clearTable()
    return

  updateTime: (t) ->
    t = t.floorDay()
    if @t0? && @t0.sameDay(t) && @id? && @id == @infoView.id
      @updateNow()
    else
      @trendCtl.requestData @infoView.id, t, t.nextHour(23), 24
    return

  updateTable: (iter) ->
    t = iter.reset()
    t0 = (new Date t).floorHour()
    if @id != iter.id || !@t0? || !@t0.sameDay(t0)
      @id = iter.id
      @t0 = t0
      hours = [0..23]
      while t?
        x = iter.x
        h = (t - t0) / HOUR
        if (td = @items[h])?
          if x?
            hours.splice hours.indexOf(h), 1
            prec  = x[0]
            temp  = x[1]
            vel   = x[3]
            dir   = x[4]
            sun   = x[5]
            fall  = x[6]
            depth = x[7]
            td[0].setText "#{h}"
            td[1].setText if temp?  then temp.toFixed 1 else NULL
            td[2].setText if prec?  then prec.toFixed 1 else NULL
            td[3].setText if vel?   then vel.toFixed 1  else NULL
            td[4].setText if dir?   then DIR[dir]       else NULL
            td[5].setText if sun?   then sun.toFixed 1  else NULL
            td[6].setText if fall?  then "#{fall}"      else NULL
            td[7].setText if depth? then "#{depth}"     else NULL
          else
            td.setText NULL for td in @items[h]
        t = iter.next()
      for h in hours
        td.setText NULL for td in @items[h]
    @updateNow()
    return

  updateNow: ->
    @setHighlight @now.hour(), false if @now?
    @now = null
    now = @weatherCtl.getTime()
    if @t0? && @t0.sameDay now
      @setHighlight now.hour(), true
      @now = now
    return

  setHighlight: (hour, hi) ->
    hi = if hi then 'highlight' else 'regular'
    item.setHighlight hi for item in @items[hour]
    return

  clearTable: ->
    for tr in @items
      for td in tr
        td.setText NULL
    return

  clickOnTable: (hour) ->
    return unless @t0
    t = @t0.nextHour hour
    if DataInfo.timeMin() <= t <= DataInfo.timeMax()
      @weatherCtl.setTime t
    return

window.DataView = DataView
