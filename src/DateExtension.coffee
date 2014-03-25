floor = Math.floor
ceil = Math.ceil
round = Math.round

SEC  = 1000
MIN  = 60 * SEC
HOUR = 60 * MIN
DAY  = 24 * HOUR
WEEK =  7 * DAY

DAYS_OF_MON = [
  [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
]

isLeapYear = (y) -> (y % 400) == 0 || ((y % 100) != 0 && (y % 4) == 0)
daysOfYear = (y) -> if isLeapYear(y) then 366 else 365
daysOfMon = (y, m) -> DAYS_OF_MON[Number isLeapYear(y)][m - 1]

YMD = (y, m, d) -> new Date y, m - 1, d
YMDH = (y, m, d, h) -> new Date y, m - 1, d, h
YMDHM = (y, m, d, h, min) -> new Date y, m - 1, d, h, min
YMDHMS = (y, m, d, h, min, s) -> new Date y, m - 1, d, h, min, s

iso8601 = (s) ->    # YYYY-MM-DD only (no hh:mm)
  return if $.type(s) != 'string'
  re = s.match /^(\d{4})-(\d\d)-(\d\d)$/
  return unless re?
  YMD parseInt(re[1]), parseInt(re[2]), parseInt(re[3])

floorSec = (d) -> new Date floor(+d / SEC) * SEC
ceilSec  = (d) -> new Date ceil( +d / SEC) * SEC
roundSec = (d) -> new Date round(+d / SEC) * SEC

floorMin = (d) -> new Date floor(+d / MIN) * MIN
ceilMin  = (d) -> new Date ceil( +d / MIN) * MIN
roundMin = (d) -> new Date round(+d / MIN) * MIN

floorHour = (d) ->
  tz = d.getTimezoneOffset() * MIN
  new Date floor((+d - tz) / HOUR) * HOUR + tz

ceilHour = (d) ->
  tz = d.getTimezoneOffset() * MIN
  new Date ceil((+d - tz) / HOUR) * HOUR + tz

roundHour = (d) ->
  tz = d.getTimezoneOffset() * MIN
  new Date round((+d - tz) / HOUR) * HOUR + tz

floorDay = (d) ->
  tz = d.getTimezoneOffset() * MIN
  new Date floor((+d - tz) / DAY) * DAY + tz

ceilDay = (d) ->
  tz = d.getTimezoneOffset() * MIN
  new Date ceil((+d - tz) / DAY) * DAY + tz

roundDay = (d) ->
  tz = d.getTimezoneOffset() * MIN
  new Date round((+d - tz) / DAY) * DAY + tz

sameYear = (a, b) ->
  a.year() == b.year()

sameMon = (a, b) ->
  a.year() == b.year() && a.mon() == b.mon()

sameDay = (a, b) ->
  a.year() == b.year() && a.mon() == b.mon() && a.day() == b.day()

sameHour = (a, b) ->
  a.year() == b.year() && a.mon() == b.mon() && a.day() == b.day() &&
  a.hour() == b.hour()

sameSec = (a, b) ->
  a.year() == b.year() && a.mon() == b.mon() && a.day() == b.day() &&
  a.hour() == b.hour() && a.sec() == b.sec()

# Date extensions
Date.SEC = SEC
Date.MIN = MIN
Date.HOUR = HOUR
Date.DAY = DAY
Date.WEEK = WEEK
Date.DAYS_OF_MON = DAYS_OF_MON

Date.isLeapYear = isLeapYear
Date.daysOfYear = daysOfYear
Date.daysOfMon = daysOfMon

Date.YMD = YMD
Date.YMDH = YMDH
Date.YMDHM = YMDHM
Date.YMDHMS = YMDHMS

Date.iso8601 = iso8601

Date.floorSec  = floorSec
Date.ceilSec   = ceilSec
Date.roundSec  = roundSec
Date.floorMin  = floorMin
Date.ceilMin   = ceilMin
Date.roundMin  = roundMin
Date.floorHour = floorHour
Date.ceilHour  = ceilHour
Date.roundHour = roundHour
Date.floorDay  = floorDay
Date.ceilDay   = ceilDay
Date.roundDay  = roundDay

Date.sameYear = sameYear
Date.sameMon  = sameMon
Date.sameDay  = sameDay
Date.sameHour = sameHour
Date::sameSec = sameSec

# Date.prototype extensions
Date::year = Date::getFullYear
Date::mon  = -> @getMonth() + 1
Date::wday = Date::getDay
Date::day  = Date::getDate
Date::hour = Date::getHours
Date::min  = Date::getMinutes
Date::sec  = Date::getSeconds
Date::msec = Date::getMilliseconds
Date::isLeapYear = -> isLeapYear @year()
Date::daysOfYear = -> daysOfYear @year()
Date::daysOfMon  = -> daysOfMon @year(), @mon()
Date::floorDay   = -> floorDay  @
Date::ceilDay    = -> ceilDay   @
Date::roundDay   = -> roundDay  @
Date::floorHour  = -> floorHour @
Date::ceilHour   = -> ceilHour  @
Date::roundHour  = -> roundHour @
Date::floorMin   = -> floorMin  @
Date::ceilMin    = -> ceilMin   @
Date::roundMin   = -> roundMin  @
Date::floorSec   = -> floorSec  @
Date::ceilSec    = -> ceilSec   @
Date::roundSec   = -> roundSec  @

Date::nextYear = (dy = 1) ->
  date = new Date +@
  date.setDate 1
  date.setFullYear @year() + dy
  d = @day()
  days = date.daysOfMon()
  d = days if d > days
  date.setDate d
  date

Date::prevYear = (dy = 1) ->
  @nextYear -dy

Date::nextMon = (dm = 1) ->
  date = new Date +@
  date.setDate 1
  date.setMonth @getMonth() + dm
  d = @day()
  days = date.daysOfMon()
  d = days if d > days
  date.setDate d
  date

Date::prevMon = (dm = 1) ->
  @nextMon -dm

Date::nextDay = (dd = 1) ->
  date = new Date +@
  date.setDate date.getDate() + dd
  date

Date::prevDay = (dm = 1) ->
  @nextDay -dm

Date::nextHour = (dh = 1) ->
  Date.YMDH @year(), @mon(), @day(), @hour() + dh

Date::prevHour = (dh = 1) ->
  @nextHour -dh

Date::nextMin = (dm = 1) ->
  Date.YMDHM @year(), @mon(), @day(), @hour(), @min() + dm

Date::prevMin = (dm = 1) ->
  @nextHour -dm

Date::nextSec = (ds = 1) ->
  Date.YMDHMS @year(), @mon(), @day(), @hour(), @min(), @sec + ds

Date::prevSec = (ds = 1) ->
  @nextHour -ds

Date::sameYear = (d) -> sameYear @, d
Date::sameMon  = (d) -> sameMon  @, d
Date::sameDay  = (d) -> sameDay  @, d
Date::sameHour = (d) -> sameHour @, d
Date::sameSec  = (d) -> sameSec  @, d

sNN = (n) -> if n < 10 then "0#{n}" else "#{n}"

Date::toString = ->
  tz = @getTimezoneOffset()
  if tz < 0
    tz = -tz
    sign = '+'
  else
    sign = '-'
  "#{@year()}-#{sNN @mon()}-#{sNN @day()} #{sNN @hour()}:#{sNN @sec()}:#{sNN((@msec() / 10) << 0)} (#{sign}#{sNN((tz / 60) << 0)}:#{sNN tz % 60})"
