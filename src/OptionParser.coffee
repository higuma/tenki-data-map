clone = MiscUtils.cloneObject

RE_KEY_VALUE = /(.+)=(.*)/      # value can be an empty string

location = window.location

parseOption = (string, option = {}) ->
  for keyValue in string.toLowerCase().split('&')
    if (re = keyValue.match RE_KEY_VALUE)?
      option[re[1]] = re[2]
  option

parseQuery = (option = {}) -> parseOption location.search.substring(1), option
parseHash = (option = {}) -> parseOption location.hash.substring(1), option
parseUrlOption = (option = {}) -> parseHash parseQuery option

gmDefaults = window.GoogleMapsDefaults

LatMin  = gmDefaults.LatMin
LatMax  = gmDefaults.LatMax
LonMin  = gmDefaults.LonMin
LonMax  = gmDefaults.LonMax
ZoomMin = gmDefaults.ZoomMin
ZoomMax = gmDefaults.ZoomMax

processGoogleMapsOption = (option, gmOption = clone gmDefaults) ->
  for key, value of option
    switch key
      when 'll'   # lat/lon
        latLon = value.split ','
        if latLon.length == 2
          lat = parseFloat latLon[0]
          lon = parseFloat latLon[1]
          if LatMin <= lat <= LatMax && LonMin <= lon <= LonMax
            gmOption.lat = lat
            gmOption.lon = lon
      when 'z'    # zoom level
        zoom = parseInt value
        gmOption.zoom = zoom if ZoomMin <= zoom <= ZoomMax
      when 't'    # map type
        gmOption.type = value
  gmOption

window.OptionParser =
  parseOption: parseOption
  parseQuery: parseQuery
  parseHash: parseHash
  parseUrlOption: parseUrlOption
  processGoogleMapsOption: processGoogleMapsOption
