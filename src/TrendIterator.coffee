class TrendIterator0    # no data
  # @id - place ID
  # @level - zoom level (0..10)
  # @tL, @tR - horizontal axis viewport
  # @t - current time
  # @x - current data
  # @hasData - true if it has actual data (not defined if not exist)
  constructor: (@id, @level, @tL, @tR) ->
    @t = @x = null      # always null
    # @hasData is undefined

  reset: ->     # empty
  next: ->      # empty

class TrendIterator1    # one data
  constructor: (@id, @level, @tL, @tR, @d, @iL, @iR) ->
    @dt = @d.dt
    @hasData = true
    @reset()

  reset: ->     # returns first @t
    @i = @iL
    @x = @d[@iL]
    @t = @d.t0 + @i * @dt

  next: ->      # returns next @t or null
    if @i != @iR
      @x = @d[++@i]
      @t += @dt
    else
      @t = @x = null

class TrendIterator2    # two data
  constructor: (@id, @level, @tL, @tR, @dL, @iL, @dR, @iR) ->
    @dt = @dL.dt
    @hasData = true
    @reset()

  reset: ->     # returns first @t
    @d = @dL
    @i = @iL
    @x = @d[@i]
    @t = @d.t0 + @i * @dt

  next: ->      # returns next @t or null
    if @d == @dL
      if ++@i != @d.length
        @x = @d[@i]
        @t += @dt
      else
        @d = @dR
        @i = 0
        @x = @d[0]
        @t = @d.t0
    else
      if @i != @iR
        @x = @d[++@i]
        @t += @dt
      else
        @t = @x = null

window.TrendIterator0 = TrendIterator0
window.TrendIterator1 = TrendIterator1
window.TrendIterator2 = TrendIterator2
