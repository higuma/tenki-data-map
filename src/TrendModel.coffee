CACHE_LIMIT = 100

cache = {}
queue = []

TYPE_POSTFIX =
  'y': ''       # year (annual)
  'd': 'x'      # decade
  'c': 'xx'     # century

class TrendModel
  # <- Conrtroller
  constructor: (@ctl) ->

  getData: (id, index, type) ->
    key = @key id, index, type
    data = cache[key]
    if @isData data
      queue.splice queue.indexOf(key), 1
      queue.push key
    data

  isData: (data) -> $.type(data) == 'string'
  isFetching: (data) -> data? && $.type(data) != 'string'

  xhr: (id, index, type) ->
    key = @key id, index, type
    if cache[key]?
      @getData id, index, type  # move to the top of cache
      return
    cache[key] = promise = $.get @path(id, index, type)
    promise.done (data) =>
      cache[key] = data
      delete cache[queue.shift()] if queue.length >= CACHE_LIMIT
      queue.push key
      @ctl.xhrDone id, index, type, data
    promise.fail (xhrObj) =>
      delete cache[key]
      @ctl.xhrFail id, index, type, xhrObj
    return

  # internal
  key: (id, index, type) ->
    if type == 'a'
      "#{id}-all"
    else
      "#{id}-#{index}#{TYPE_POSTFIX[type]}"

  path: (id, index, type) ->
    if type == 'a'
      "data/hourly/trend/all/#{id}.csv"
    else
      "data/hourly/trend/#{index}#{TYPE_POSTFIX[type]}/#{id}.csv"

TrendModel.TYPE_POSTFIX = TYPE_POSTFIX

window.TrendModel = TrendModel
