DATAINFO_PATH = 'data/datainfo'

INTERVAL_ON_DONE = 60 * 60 * 1000       # 1 hour
INTERVAL_ON_FAIL =  1 * 60 * 1000       # 1 minute

# notification manager
class UpdateNotifier
  constructor: -> @handlers = []
  add: (handler) -> @handlers.push(handler)
  notify: -> handler() for handler in @handlers

notifier = new UpdateNotifier

# update checker daemon
updateData = (data) ->
  for line in data.split "\n"
    first = Date.iso8601 re[1] if (re = data.match /firstdayhourly:\s*(.*)/)?
    last  = Date.iso8601 re[1] if (re = data.match /lastdayhourly:\s*(.*)/)?
  if first? && last?
    hourly = DataInfo.hourly
    if first < hourly.firstDay || hourly.lastDay < last
      hourly.firstDay = first
      hourly.lastDay = last
      notifier.notify()

checkUpdate = ->
  promise = $.get DATAINFO_PATH
  promise.done (data) =>
    updateData data
    setTimeout checkUpdate, INTERVAL_ON_DONE
  promise.fail (data) =>
    console.log "#{new Date}: Cannot load: #{DATAINFO_PATH}"
    setTimeout checkUpdate, INTERVAL_ON_FAIL

setTimeout checkUpdate, INTERVAL_ON_DONE    # start daemon

window.UpdateChecker =
  add: (handler) -> notifier.add handler
