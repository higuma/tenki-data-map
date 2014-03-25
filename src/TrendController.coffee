ceil = Math.ceil
floor = Math.floor
limitMin = MiscUtils.limitMin
limitMax = MiscUtils.limitMax
limitMinMax = MiscUtils.limitMinMax

CACHE_LIMIT = 50

cache = {}
queue = []

cacheKey = (id, index, type) ->
  if type == 'a'
    "#{id}-all"
  else
    "#{id}-#{index}#{TYPE_POSTFIX[type]}"

TYPE_POSTFIX = TrendModel.TYPE_POSTFIX

DELTA_TIME = TrendDecoder.DELTA_TIME

class TrendController
  constructor: (view = null) ->
    @model = new TrendModel @
    @views = []
    @decoder = new TrendDecoder
    UpdateChecker.add => @onUpdateData()
    @addView view if view?

  addView: (v) -> @views.push v if @views.indexOf(v) == -1
  removeView: (v) -> @views.splice i, 1 if (i = @views.indexOf v) != -1

  # <- View
  requestData: (id, tL, tR, nData) ->
    tL = new Date(tL) if $.type(tL) == 'number'
    tR = new Date(tR) if $.type(tR) == 'number'
    @pending = p =
      id: id
      tL: tL
      tR: tR
    dt = (tR - tL) / nData
    level = DELTA_TIME.length - 1
    while level != 0 && DELTA_TIME[level] > dt
      --level
    p.level = level
    tL = tL.ceilHour().prevHour()   # ceil and adjust hour offset
    tR = tR.ceilHour().prevHour()   # (daily data ranges from 01:00 to 24:00)
    if level < 4        # 0-3: full data
      p.ty = 'y'
      p.iL = tL.year()
      p.iR = tR.year()
    else if level < 7   # 4-6: 12h step
      p.ty = 'd'
      p.iL = (tL.year() / 10) >> 0
      p.iR = (tR.year() / 10) >> 0
    else if level < 10  # 7-9: 4d step
      p.ty = 'c'
      p.iL = (tL.year() / 100) >> 0
      p.iR = (tR.year() / 100) >> 0
    else                # 10-12: 64d step (top level)
      p.ty = 'a'
      p.iL = p.iR = 0   # (not used)
    @resolvePending()

  # <- Model
  xhrDone: (id, index, type, data) ->
    @setNewData id, index, type, data
    @resolvePending()
    return

  xhrFail: (id, index, type, xhrObj) ->
    if xhrObj.status == 404
      @rescuePending id, index, type
    else
      @updateViews false
    return

  # <- Update Checker
  onUpdateData: ->
    v.onUpdateData() for v in @views
    return

  # internal
  resolvePending: (p = @pending) ->
    if p? && (dL = @getData p.id, p.iL, p.ty)?
      dR = if p.iL == p.iR then dL else @getData p.id, p.iR, p.ty
      @setIterator dL, dR if dR?
    return

  rescuePending: (id, index, type, p = @pending) ->
    if p? && id == p.id && type == p.ty
      if index == p.iL
        if p.iL == p.iR
          @setIterator null
        else
          p.iL = p.iR
          @resolvePending()
      else if index == p.iR
        p.iR = p.iL
        @resolvePending()
    return

  getData: (id, index, type) ->
    key = cacheKey id, index, type
    if (data = cache[key])?
      queue.splice queue.indexOf(key), 1
      queue.push key
    else if (input = @model.getData id, index, type)?
      data = @setNewData id, index, type, input if @model.isData input
    else
      @model.xhr id, index, type
    data

  setIterator: (dL, dR, p = @pending) ->
    @iterator = if dL?
      tLL = limitMin p.tL, DataInfo.timeMin()
      tRR = limitMax p.tR, DataInfo.timeMax()
      dL = dL[p.level]
      jL = limitMinMax ceil((tLL - dL.t0) / dL.dt), 0, dL.length - 1
      if p.iL == p.iR
        jR = limitMinMax ceil((tRR - dL.t0) / dL.dt), 0, dL.length - 1
        new TrendIterator1 p.id, p.level, p.tL, p.tR, dL, jL, jR
      else
        dR = dR[p.level]
        jR = limitMinMax ceil((tRR - dR.t0) / dR.dt), 0, dR.length - 1
        new TrendIterator2 p.id, p.level, p.tL, p.tR, dL, jL, dR, jR
    else
      new TrendIterator0 p.id, p.level, p.tL, p.tR    # data not exist
    @pending = null
    @updateViews true
    return


  setNewData: (id, index, type, input) ->
    key = cacheKey id, index, type
    data = cache[key] = @decoder.decode index, type, input
    delete cache[queue.shift()] if queue.length >= CACHE_LIMIT
    queue.push key
    data

  updateViews: (success) ->
    v.update @, success for v in @views
    return

window.TrendController = TrendController
