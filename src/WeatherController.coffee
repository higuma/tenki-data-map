class WeatherController
  constructor: (view = null) ->
    @model = new WeatherModel @
    @views = []
    @decoder = new WeatherDecoder
    @day = null         # Date object
    @hour = null        # 0(01:00) .. 23(24:00)
    @xhrDay = @xhrHour = null
    @data = null
    @interval = null
    @timer = null
    @firstDay = DataInfo.hourly.firstDay
    @lastDay = DataInfo.hourly.lastDay
    UpdateChecker.add => @onUpdateData()
    @addView view if view?

  addView: (v) ->
    @views.push v if @views.indexOf(v) == -1
    return

  removeView: (v) ->
    @views.splice i, 1 if (i = @views.indexOf v) != -1
    return

  # <-> View
  getData: -> if @data? then @data[@hour % 6] else null

  isLastData: -> @isSameData @lastDay, 23
  isLastFrame: -> @isLastData() && @hour == 23

  getTime: ->
    Date.YMDH @day.year(), @day.mon(), @day.day(), @hour + 1 if @day

  setTime: (t) ->
    t = new Date(t) if $.type(t) == 'number'
    t = DataInfo.ceilHour t
    d = Date.YMDH t.year(), t.mon(), t.day(), t.hour() - 1
    @requestData d, d.hour()
    return

  prefetchNextData: ->
    unless @isLastData()
      day = @day
      hour = @hour + 6
      if hour >= 24
        hour -= 24
        day = day.nextDay()
      @model.xhr day, hour unless (@model.getData day, hour)?
    return

  # <- Model
  xhrDone: (day, hour, data) ->
    if @xhrDay? && @xhrDay.sameDay(day) && @xhrHour == hour
      @setNewData day, hour, data
      @setAnim @interval, true if @interval
    return

  xhrFail: (day, hour, xhrObj) ->
    @updateViews false
    return

  # <- Update Checker
  onUpdateData: ->
    @firstDay = DataInfo.hourly.firstDay
    @lastDay = DataInfo.hourly.lastDay
    v.onUpdateData() for v in @views
    return

  # animation
  setAnim: (msec, reset = false) ->     # msec = null to stop
    return if !reset && @interval == msec
    @interval = msec
    clearTimeout @timer if @timer?
    if @interval?
      @prefetchNextData()
      @timer = setTimeout (=> @onTimer()), @interval
    else
      @timer = null
    return

  onTimer: ->
    day = @day
    hour = @hour + 1
    if (hour % 6) != 0
      @hour = hour
      @updateViews true
      if @isLastFrame()
        @interval = @timer = null
        return
    else
      if hour == 24
        hour = 0
        day = day.nextDay()
      data = @model.getData day, hour
      if @model.isData data
        @setNewData day, hour, data
        @prefetchNextData()
    @timer = setTimeout (=> @onTimer()), @interval
    return

  # internal
  isSameData: (d, h) ->
    @day? && @day.sameDay(d) && (@hour / 6) >> 0 == (h / 6) >> 0

  requestData: (day, hour) ->
    if @isSameData day, hour
      if @hour != hour
        @hour = hour
        @updateViews true
        @setAnim @interval, true if @interval
      return
    data = @model.getData day, hour
    if @model.isData data
      @setNewData day, hour, data
      @setAnim @interval, true if @interval
    else if !@model.isFetching data
      @xhrDay = day
      @xhrHour = hour
      @model.xhr day, hour
    return

  setNewData: (day, hour, data) ->
    @day = day
    @hour = hour
    @xhrDay = @xhrHour = null
    @data = @decoder.decode data
    @updateViews true
    return

  updateViews: (success) ->
    v.update @, success for v in @views
    return

window.WeatherController = WeatherController
