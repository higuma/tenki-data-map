ceil = Math.ceil

# assumes 1 < d < 2000 (not a general implementation)

H_DEFAULT = 270

class ValueScaleIterator
  ###
    @ds   main scale step
    @dss  subscale step
    @fs   main scale label fraction digit (undefined for 0)
  ###

  constructor: (@v0, @v1, h) ->
    d = (@v1 - @v0) * H_DEFAULT / h
    if d < 2
      @ds = 0.2
      @dss = 0.1
      @fs = 1
    else if d < 4
      @ds = 0.5
      @dss = 0.1
      @fs = 1
    else if d < 8
      @ds = 1
      @dss = 0.2
    else if d < 20
      @ds = 2
      @dss = 0.5
    else if d < 40
      @ds = 5
      @dss = 1
    else if d < 80
      @ds = 10
      @dss = 2
    else if d < 200
      @ds = 20
      @dss = 5
    else if d < 400
      @ds = 50
      @dss = 10
    else if d < 800
      @ds = 100
      @dss = 20
    else
      @ds = 200
      @dss = 50
    @di = @ds / @dss

  reset: -> @set ceil @v0 / @dss
  next: -> @set ++@i

  set: (@i) ->
    if (@v = @i * @dss) <= @v1
      @s = if (@i % @di) == 0
        if @fs?
          @v.toFixed @fs
        else
          "#{@v}"
      else
        null
      @v
    else
      @v = @s = null

window.ValueScaleIterator = ValueScaleIterator
