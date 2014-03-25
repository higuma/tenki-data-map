# DataInfo.js extension

limitMinMax = MiscUtils.limitMinMax

timeMin = ->
  d = DataInfo.hourly.firstDay
  Date.YMDH d.year(), d.mon(), d.day(), 1

timeMax = ->
  d = DataInfo.hourly.lastDay
  Date.YMDH d.year(), d.mon(), d.day(), 24

floorHour = (d) -> limitMinMax d.floorHour(), timeMin(), timeMax()
ceilHour  = (d) -> limitMinMax d.ceilHour(),  timeMin(), timeMax()
roundHour = (d) -> limitMinMax d.roundHour(), timeMin(), timeMax()

WIND_DIRECTION = [
  '北', '北北東', '北東', '東北東', '東', '東南東', '南東', '南南東'
  '南', '南南西', '南西', '西南西', '西', '西北西', '北西', '北北西'
  '静穏'
]

DataInfo.timeMin = timeMin
DataInfo.timeMax = timeMax
DataInfo.floorHour = floorHour
DataInfo.ceilHour  = ceilHour
DataInfo.roundHour = roundHour
DataInfo.WIND_DIRECTION = WIND_DIRECTION
