ceil = Math.ceil

min = (x, y) ->
  if x?
    if y?
      if x < y then x else y
    else
      x
  else
    y

max = (x, y) ->
  if x?
    if y?
      if x > y then x else y
    else
      x
  else
    y

DELTA_TIME = [
  3600000       # level 0: 1h
  7200000       # level 1: 2h
  14400000      # level 2: 4h
  28800000      # level 3: 8h
  43200000      # level 4: 12h
  86400000      # level 5: 24h = 1d
  172800000     # level 6: 2d
  345600000     # level 7: 4d
  691200000     # level 8: 8d
  1382400000    # level 9: 16d
  2764800000    # level 10: 32d
  5529600000    # level 11: 64d
  11059200000   # level 12: 128d
]

daysOfYear = Date.daysOfYear

totalDays = (yearFrom, yearTo) ->
  days = 0
  for year in [yearFrom..yearTo]
    days += daysOfYear(year)
  days

N_DATA_ALL = ceil totalDays(1800, 2099) / 32

class TrendDecoder
  constructor: ->

  decode: (index, type, input) ->
    switch type
      when 'y' then @decodeYear index, input
      when 'd' then @decodeDecade index, input
      when 'c' then @decodeCentury index, input
      when 'a' then @decodeAll input

  decodeYear: (year, input) ->
    t0 = +(Date.YMDH year, 1, 1, 1)     # begins from 01:00 (not 00:00)
    data = @decodeY year, input
    data.t0 = t0
    data.dt = DELTA_TIME[0]
    levels = [data]     # level 0
    for i in [1..3]     # level 1, 2, 3
      levels.push data = @makeStat data
      data.t0 = t0
      data.dt = DELTA_TIME[i]
    levels

  decodeDecade: (decade, input) ->
    year = decade * 10
    t0 = +(Date.YMDH year, 1, 1, 1)     # begins from 01:00 (not 00:00)
    data = @decodeDCA totalDays(year, year + 9) * 2, input
    data.t0 = t0
    data.dt = DELTA_TIME[4]
    levels = []
    levels[4] = data    # level 4
    for i in [5..6]     # level 5, 6
      levels[i] = data = @makeStat data
      data.t0 = t0
      data.dt = DELTA_TIME[i]
    levels

  decodeCentury: (century, input) ->
    year = century * 100
    t0 = +(Date.YMDH year, 1, 1, 1)     # begins from 01:00 (not 00:00)
    data = @decodeDCA ceil(totalDays(year, year + 99) / 4), input
    data.t0 = t0
    data.dt = DELTA_TIME[7]
    levels = []
    levels[7] = data    # level 7
    for i in [8..9]     # level 8, 9
      levels[i] = data = @makeStat data
      data.t0 = t0
      data.dt = DELTA_TIME[i]
    levels

  decodeAll: (input) ->
    data = @decodeDCA N_DATA_ALL, input
    t0 = +(Date.YMDH 1800, 1, 1, 1)     # begins from 01:00 (not 00:00)
    data.t0 = t0
    data.dt = DELTA_TIME[10]
    levels = []
    levels[10] = data   # level 10
    for i in [11..12]   # level 11, 12
      levels[i] = data = @makeStat data
      data.t0 = t0
      data.dt = DELTA_TIME[i]
    levels

  decodeY: (year, input) ->
    c = new CsvParser input
    [fp, ft, fv, fd, fl, ff, fs] = @parseFlags c.get_i()
    trend = []
    for i in [0...daysOfYear(year)]
      if c.get_i()?
        for hour in [0...24]
          trend.push [
            if fp then c.get_f() else null      # precipitation
            t = if ft then c.get_f() else null  # temperature (min)
            t                                   # temperature (max)
            if fv then c.get_f() else null      # wind velocity
            if fd then c.get_i() else null      # wind direction
            if fl then c.get_f() else null      # sunlight
            if ff then c.get_i() else null      # snowfall
            if fs then c.get_i() else null      # snow depth
          ]
      else
        trend.push null for hour in [0...24]
    trend

  decodeDCA: (nData, input) ->
    c = new CsvParser input
    [fp, ft, fv, fd, fl, ff, fs] = @parseFlags c.get_i()
    trend = []
    for i in [0...nData]
      if c.get_i()?
        trend.push [
          if fp then c.get_f() else null        # precipitation
          if ft then c.get_f() else null        # temperature (min)
          if ft then c.get_f() else null        # temperature (max)
          if fv then c.get_f() else null        # wind velocity
          if fd then c.get_i() else null        # wind direction
          if fl then c.get_f() else null        # sunlight
          if ff then c.get_i() else null        # snowfall
          if fs then c.get_i() else null        # snow depth
        ]
      else
        trend.push null
    trend

  parseFlags: (flags) ->
    [ (flags &  1) != 0         # precpitation
      (flags &  2) != 0         # temperature
      (flags &  4) != 0         # wind velocity
      (flags &  8) != 0         # wind direction
      (flags & 16) != 0         # sunlight
      (flags & 32) != 0         # snowfall
      (flags & 64) != 0         # snow depth
    ]

  makeStat: (data) ->
    stat = []
    length = data.length
    i = 0
    while i < length
      if i == length - 1
        stat.push data[i]
        return stat
      else
        x = data[i]
        y = data[i + 1]
        if x?
          if y?
            [px, t0x, t1x, vx, dx, lx, fx, sx] = x
            [py, t0y, t1y, vy, dy, ly, fy, sy] = y
            v = d = null
            if vx?
              if vy?
                if vx > vy
                  v = vx
                  d = dx
                else
                  v = vy
                  d = dy
              else
                v = vx
                d = dx
            else
              v = vy
              d = dy
            stat.push [
              max px, py
              min t0x, t0y
              max t1x, t1y
              v
              d
              max lx, ly
              max fx, fy
              max sx, sy
            ]
          else  # x? && !y?
            stat.push x
        else    # !x?
          stat.push y
        i += 2
    stat

TrendDecoder.DELTA_TIME = DELTA_TIME

window.TrendDecoder = TrendDecoder
