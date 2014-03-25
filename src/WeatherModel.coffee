CACHE_LIMIT = 100

cache = {}
queue = []

class WeatherModel
  # <- Conrtroller
  constructor: (@ctl) ->

  getData: (day, hour) ->
    key = @key day, (hour / 6) >> 0
    data = cache[key]
    if @isData data
      queue.splice queue.indexOf(key), 1
      queue.push key
    data

  isData: (data) -> $.type(data) == 'string'
  isFetching: (data) -> data? && $.type(data) != 'string'

  xhr: (day, hour) ->
    index = (hour / 6) >> 0
    key = @key day, index
    if cache[key]?
      @getData day hour         # move to the top of cache
      return
    cache[key] = promise = $.get @path(day, index)
    promise.done (data) =>
      cache[key] = data
      delete cache[queue.shift()] if queue.length >= CACHE_LIMIT
      queue.push key
      @ctl.xhrDone day, hour, data
    promise.fail (xhrObj) =>
      delete cache[key]
      @ctl.xhrFail day, hour, xhrObj

  # internal
  sNN: (n) -> if n < 10 then "0#{n}" else "#{n}"

  key: (d, i) ->
    "#{d.year()}-#{d.mon()}-#{d.day()}-#{i}"

  path: (d, i) ->
    "data/hourly/map/#{d.year()}/#{@sNN d.mon()}#{@sNN d.day()}/#{i}.csv"

window.WeatherModel = WeatherModel
