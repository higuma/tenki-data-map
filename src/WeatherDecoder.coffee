NDATA = 6

class WeatherDecoder
  constructor: ->

  decode: (input) ->
    p = new CsvParser input
    data = ({} for i in [0...NDATA])
    nPlace = p.get_i()
    for dummy in [0...nPlace]
      id = p.get_i()
      flags = p.get_i()
      hasP = (flags &  1) != 0  # precpitation
      hasT = (flags &  2) != 0  # temperature
      hasV = (flags &  4) != 0  # wind velocity
      hasD = (flags &  8) != 0  # wind direction
      hasL = (flags & 16) != 0  # sunlight
      hasF = (flags & 32) != 0  # snowfall
      hasS = (flags & 64) != 0  # snow depth
      for d in data
        d[id] = [
          if hasP then p.get_f() else null  # precipitation
          if hasT then p.get_f() else null  # temperature
          if hasV then p.get_f() else null  # wind velocity
          if hasD then p.get_i() else null  # wind direction
          if hasL then p.get_f() else null  # sunlight
          if hasF then p.get_i() else null  # snowfall
          if hasS then p.get_i() else null  # snow depth
        ]
    data

window.WeatherDecoder = WeatherDecoder
