###
Generic specification
---------------------

constructor function

    TimeScaleIterator(l, r) - returns an instance object

        l - left time bounds
        r - right time bounds

instance properties

    @l - left bounds
    @r - right bounds
    @t - current time position (null for end)
    @s - current label string (null for subscale or end)

instance methods

    reset() - rewind to the initial position, returns leftmost @p
    next() - goto next position, returns updated @p (null for end)
###

ceil = Math.ceil
floor = Math.floor

MIN  = Date.MIN
HOUR = Date.HOUR
DAY  = Date.DAY
WEEK = Date.WEEK

W_DEFAULT = 465

class I_h
  constructor: (@l, @r, @dss, @ds, @dt) ->
    @tz = (new Date +@l).getTimezoneOffset() * MIN
    @step = @dss * HOUR

  reset: -> @setT ceil((@l - @tz) / @step) * @step + @tz
  next: -> @setT @t + @step

  setT: (@t) ->
    if @t > @r
      @t = @s = null
    else
      d = new Date +@t
      h = d.hour()
      @s = if h == 0
        "#{d.mon()}/#{d.day()}" # main scale with a day label (e.g. 12/25)
      else if (h % @dt) == 0
        "#{h}:00"               # main scale with an hour label (e.g. 12:00)
      else if (h % @ds) == 0
        ''                      # main scale with no label
      else
        null                    # subscale
      @t

class I_d_h
  constructor: (@l, @r, @dss) ->
    @tz = (new Date +@l).getTimezoneOffset() * MIN
    @step = @dss * HOUR

  reset: -> @setT ceil((@l - @tz) / @step) * @step + @tz
  next: -> @setT @t + @step

  setT: (@t) ->
    if @t > @r
      @t = @s = null
    else
      d = new Date +@t
      h = d.hour()
      @s = if h == 0
        if d.wday() == 0
          "#{d.mon()}/#{d.day()}"   # Sunday
        else
          "#{d.day()}"              # weekday
      else
        null                        # subscale
      @t

class I_w_h
  constructor: (@l, @r, @dss) ->
    @tz = (new Date +@l).getTimezoneOffset() * MIN
    @step = @dss * HOUR

  reset: -> @setT ceil((@l - @tz) / @step) * @step + @tz
  next: -> @setT @t + @step

  setT: (@t) ->
    if @t > @r
      @t = @s = null
    else
      d = new Date +@t
      h = d.hour()
      @s = if h == 0
        if d.wday() == 0
          "#{d.mon()}/#{d.day()}"   # Sunday
        else
          ''                        # weekday
      else
        null                        # subscale
      @t

class I_w_d
  constructor: (@l, @r) ->
    @tz = (new Date +@l).getTimezoneOffset() * MIN

  reset: -> @setT ceil((@l - @tz) / DAY) * DAY + @tz
  next: -> @setT @t + DAY

  setT: (@t) ->
    if @t > @r
      @t = @s = null
    else
      d = new Date +@t
      @s = if d.wday() == 0
        "#{d.mon()}/#{d.day()}"     # Sunday
      else
        null                        # subscale
      @t

class I_m_d
  constructor: (@l, @r) ->
    @tz = (new Date +@l).getTimezoneOffset() * MIN

  reset: -> @setT ceil((@l - @tz) / DAY) * DAY + @tz
  next: -> @setT @t + DAY

  setT: (@t) ->
    if @t > @r
      @t = @s = null
    else
      d = new Date +@t
      @s = if d.day() == 1
        "#{d.mon()}/#{d.day()}"     # 1st day of month
      else if d.wday() == 0
        ''                          # sunday
      else
        null                        # subscale
      @t

class I_m_w
  constructor: (@l, @r) ->
    @tz = (new Date +@l).getTimezoneOffset() * MIN

  reset: -> @setT ceil((@l - @tz) / DAY) * DAY + @tz
  next: -> @setT @t + DAY

  setT: (@t) ->
    while @t <= @r
      d = new Date +@t
      if d.day() == 1
        @s = if d.mon() == 1
          "#{d.year()}"
        else
          "#{d.mon()}"
        return @t
      if d.wday() == 0
        @s = null
        return @t
      @t += DAY
    @t = @s = null

class I_m
  constructor: (@l, @r, @ds) ->

  reset: ->
    d = new Date +@l
    @d = Date.YMDH d.year(), d.mon() + 1, 1, 0
    @setT +@d

  next: -> @setT +(@d = @d.nextMon())

  setT: (@t) ->
    if @t > @r
      @t = @s = null
    else
      @s = if (m = @d.mon()) == 1
        "#{@d.year()}"
      else if (m % @ds) == 1
        "#{m}"
      else
        null
      @t

class I_y_m
  constructor: (@l, @r, @dss, @ds) ->

  reset: ->
    d = new Date +@l
    @d = Date.YMDH d.year(), d.mon() + 1, 1, 0
    if @dss > 1
      until (@d.mon() % @dss) == 1
        @d = @d.nextMon()
    @setT +@d

  next: -> @setT +(@d = @d.nextMon @dss)

  setT: (@t) ->
    if @t > @r
      @t = @s = null
    else
      @s = if (m = @d.mon()) == 1
        "#{@d.year()}"
      else if (m % @ds) == 1
        ''
      else
        null
      @t

class I_y
  constructor: (@l, @r, @dss, @ds, @dt) ->

  reset: ->
    d = new Date +@l
    @d = Date.YMDH d.year() + 1, 1, 1, 0
    if @dss > 1
      until (@d.year() % @dss) == 0
        @d = @d.nextYear()
    @setT +@d

  next: -> @setT +(@d = @d.nextYear @dss)

  setT: (@t) ->
    if @t > @r
      @t = @s = null
    else
      y = @d.year()
      @s = if (y % @dt) == 0
        "#{@d.year()}"
      else if (y % @ds) == 0
        ''
      else
        null
      @t

TimeScaleIterator = (l, r, w) ->
  w = (r - l) * W_DEFAULT / w
  if w < DAY
    new I_h l, r, 1, 3, 3
  else if w < 2 * DAY
    new I_h l, r, 1, 3, 6
  else if w < 3 * DAY
    new I_h l, r, 3, 6, 12
  else if w < 4 * DAY
    new I_h l, r, 3, 12, 12
  else if w < 5 * DAY
    new I_h l, r, 3, 12, 24
  else if w < 7 * DAY
    new I_h l, r, 6, 12, 24
  else if w < 10 * DAY
    new I_h l, r, 6, 24, 24
  else if w < 12 * DAY
    new I_h l, r, 12, 24, 24
  else if w < 16 * DAY
    new I_d_h l, r, 12
  else if w < 25 * DAY
    new I_w_h l, r, 12
  else if w < 72 * DAY
    new I_w_d l, r, 24
  else if w < 100 * DAY
    new I_m_d l, r
  else if w < 500 * DAY
    new I_m_w l, r
  else if w < 1200 * DAY
    new I_m l, r, 3
  else if w < 1800 * DAY
    new I_y_m l, r, 1, 6
  else if w < 2400 * DAY
    new I_y_m l, r, 3, 6
  else if w < 3600 * DAY
    new I_y_m l, r, 3, 12
  else if w < 5000 * DAY
    new I_y_m l, r, 6, 12
  else if w < 8000 * DAY
    new I_y l, r, 1, 2, 2
  else if w < 16000 * DAY
    new I_y l, r, 1, 5, 5
  else if w < 32000 * DAY
    new I_y l, r, 1, 5, 10
  else
    new I_y l, r, 2, 10, 20

window.TimeScaleIterator = TimeScaleIterator
