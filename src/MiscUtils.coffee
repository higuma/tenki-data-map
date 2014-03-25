# Miscellaneous Utilities

limitMin = (x, min) ->
  if x < min
    min
  else
    x

limitMax = (x, max) ->
  if x > max
    max
  else
    x

limitMinMax = (x, min, max) ->
  if x < min
    min
  else if x > max
    max
  else
    x

cloneObject = (obj) ->          # make a shallow copy
  copy = {}
  for key, value of obj
    copy[key] = value
  copy

removeChildren = (node) ->
  while (e = node.firstChild)?
    node.removeChild e
  return

class LinMap
  constructor: (@x0, @x1, @y0, @y1) ->
    @a = (@y1 - @y0) / (@x1 - @x0)
    @b = @y0 - @a * @x0

  y: (x) -> @a * x + @b

class LinMapLimitX
  constructor: (@x0, @x1, @y0, @y1) ->
    @a = (@y1 - @y0) / (@x1 - @x0)
    @b = @y0 - @a * @x0

  y: (x) ->
    if x < @x0
      @y0
    else if x > @x1
      @y1
    else
      @a * x + @b

window.MiscUtils =
  limitMin: limitMin
  limitMax: limitMax
  limitMinMax: limitMinMax
  cloneObject: cloneObject
  removeChildren: removeChildren
  LinMap: LinMap
  LinMapLimitX: LinMapLimitX
