RE_OPTION_D = /^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)$/

CIRCLE_TYPE = ['t', 'p', 's', 'f', 'd']

ITEMS_SPEED = [['遅い', 0], ['通常', 1], ['速い', 2], ['最速', 3]]

ITEMS_CIRCLE = [
  ['気温', 't']
  ['降水', 'p']
  ['日照', 's']
  ['降雪', 'f']
  ['積雪', 'd']
]

ITEMS_SIZE = [['なし', 0], ['小', 1], ['中', 2], ['大', 3]]

isChrome = navigator.userAgent.indexOf('Chrome') != -1

ARROW_L = if isChrome then '◀' else '◂'
ARROW_R = if isChrome then '▶' else '▸'

IS_PC = Pref.platform == 'pc'

addSelectItems = (sel, items) ->
  sel.add item[0], item[1] for item in items

updateSelectRange = (sel, min, max) ->
  for opt in sel.options()
    opt.disabled = !(min <= parseInt(opt.value) <= max)

class WeatherControlView
  constructor: (@weatherView) ->
    @ctl = @weatherView.ctl
    @frame = new GoogleMapsWidget.Frame
    @createDateTimeControls()
    @createOptionControls()
    @createDisplay()
    @infoView = new InfoView @frame, @weatherView

    frame = @frame.getElement()
    frame.index = 1
    googleControls = @weatherView.getMap().controls
    googleControls[google.maps.ControlPosition.TOP_CENTER].push frame

  createDateTimeControls: ->
    row = @frame.addRow()
    (@prevY = row.addButton ARROW_L, '1年前', => @buttonPrevY()) if IS_PC
    @selY = row.addSelect => @selectDate()
    @selY.setTitle '年の設定'
    @updateSelY()
    (@nextY = row.addButton ARROW_R, '1年後', => @buttonNextY()) if IS_PC
    row.addText '年'
    row.addSpacer 2
    (@prevM = row.addButton ARROW_L, '1ヶ月前', => @buttonPrevM()) if IS_PC
    @selM = row.addSelect => @selectDate()
    @selM.setTitle '月の設定'
    for m in [1..12]
      @selM.add "#{m}", "#{m}"
    (@nextM = row.addButton ARROW_R, '1ヶ月後', => @buttonNextM()) if IS_PC
    row.addText '月'
    row.addSpacer 2
    @prevD = row.addButton ARROW_L, '1日前', => @buttonPrevD()
    @selD = row.addSelect => @selectDate()
    @selD.setTitle '日の設定'
    for d in [1..31]
      @selD.add "#{d}", "#{d}"
    @nextD = row.addButton ARROW_R, '1日後', => @buttonNextD()
    row.addText '日'
    row.addSpacer 2
    @prevH = row.addButton ARROW_L, '1時間前', => @buttonPrevH()
    @selH = row.addSelect => @selectDate()
    @selH.setTitle '時の設定'
    for h in [0..23]
      @selH.add "#{h}","#{h}"
    @nextH = row.addButton ARROW_R, '1時間後', => @buttonNextH()
    row.addText '時'

  createOptionControls: ->
    row = @frame.addRow()
    @play = row.addButton '&nbsp;再生&nbsp;', '再生/停止', => @buttonPlay()
    @selA = row.addSelect => @selectA()
    @selA.setTitle '再生速度'
    addSelectItems @selA, ITEMS_SPEED
    row.addSpacer 2
    if IS_PC
      @radC = row.addRadioGroup (i) => @radioC i
      @radC.add '気温', '気温を表示'
      @radC.add '降水', '降水量を表示'
      @radC.add '日照', '日照時間を表示'
      @radC.add '降雪', '降雪量を表示'
      @radC.add '積雪', '積雪量を表示'
      @radC.finalize()
    else
      @selC = row.addSelect => @selectC()
      @selC.setTitle '円の表示タイプ'
      addSelectItems @selC, ITEMS_CIRCLE
    row.addSpacer 1
    @selS = row.addSelect => @selectS()
    @selS.setTitle '円のサイズ'
    addSelectItems @selS, ITEMS_SIZE
    row.addSpacer 2
    row.addText '風速'
    row.addSpacer 1
    @selW = row.addSelect => @selectW()
    @selW.setTitle '風速・風向の表示サイズ'
    addSelectItems @selW, ITEMS_SIZE
    row.addSpacer 2
    row.addButton '&nbsp;保存&nbsp;', '状態をブラウザ履歴に保存', => @saveURL()

  createDisplay: ->
    row = @frame.addRow()
    rowElem = row.getElement()
    rowElem.css
    $(rowElem).css
      width: "100%"
      height: "25px"
    link = if IS_PC
      "<a href='index_m.html'class='noDeco'>モバイル版</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
    else
      "<a href='index_p.html'class='noDeco'>PC版&nbsp;&nbsp;&nbsp;&nbsp;</a>"
    @disp = new GradationDisplay rowElem, @weatherView
    $(rowElem).append $("<div id='tenkiLinks'><br />#{link}<a href='https://github.com/higuma/tenki-data-map' class='noDeco'>天気データマップについて...</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</div>")

  parseOption: (opt, @option) ->
    # read option and merge to @option
    for key, value of opt
      switch key
        when 'c'                # circle type
          switch value
            when 't', 'p', 's', 'f', 'd'
              @option[key] = value
        when 's', 'w', 'a'      # circle size, wind size, animation speed
          @option[key] = v if 0 <= (v = parseInt value) <= 3
        when 'd'                # date (+ hour)
          if (re = value.match RE_OPTION_D)?
            d = Date.YMDHM parseInt(re[1]), parseInt(re[2]), parseInt(re[3]),
                           parseInt(re[4]), parseInt(re[5])
            d = d.ceilHour()
            @option.d = d if DataInfo.timeMin() <= d <= DataInfo.timeMax()
        else
          @option[key] = value  # merge to @option (and send to InfoView)
    return

  processOption: (opt, @option) ->
    @parseOption opt, @option

    @selA.select @option.a
    if IS_PC
      @radC.select CIRCLE_TYPE.indexOf(@option.c)
    else
      @selC.select @option.c
    @selS.select @option.s
    @selW.select @option.w
    @disp.setGrad @option.c
    @infoView.processOption @option
    return

  sNN: (n) -> if n < 10 then "0#{n}" else "#{n}"

  dateQueryString: ->
    d = @ctl.getTime()
    "#{d.year()}#{@sNN d.mon()}#{@sNN d.day()}#{@sNN d.hour()}#{@sNN d.min()}"

  updateSelY: ->
    yMin = DataInfo.timeMin().year()
    yMax = DataInfo.timeMax().year()
    options = @selY.options()
    if options.length > 0
      y0 = parseInt options[0].value
      y1 = parseInt options[options.length - 1].value
      return if y0 == yMin && y1 == yMax
    @selY.clear()
    @selY.add "#{y}", "#{y}" for y in [yMin..yMax]
    return

  updateDate: ->
    @updateSelY()
    d = @ctl.getTime()
    document.title = "天気データマップ " +
                     "#{d.year()}年#{d.mon()}月#{d.day()}日#{d.hour()}時"
    tMin = DataInfo.timeMin()
    tMax = DataInfo.timeMax()
    m0 = if d.sameYear(tMin) then tMin.mon() else 1
    m1 = if d.sameYear(tMax) then tMax.mon() else 12
    updateSelectRange @selM, m0, m1
    d0 = if d.sameMon(tMin) then tMin.day() else 1
    d1 = if d.sameMon(tMax) then tMax.day() else d.daysOfMon()
    updateSelectRange @selD, d0, d1
    h0 = if d.sameDay(tMin) then 1 else 0
    h1 = if d.sameDay(tMax) then 0 else 23
    updateSelectRange @selH, h0, h1
    @selY.select d.year()
    @selM.select d.mon()
    @selD.select d.day()
    @selH.select d.hour()
    hasPrev = !d.sameHour(tMin)
    hasNext = !d.sameHour(tMax)
    if IS_PC
      @prevY.enable hasPrev
      @nextY.enable hasNext
      @prevM.enable hasPrev
      @nextM.enable hasNext
    @prevD.enable hasPrev
    @nextD.enable hasNext
    @prevH.enable hasPrev
    @nextH.enable hasNext

  update: (success) ->
    return unless success && @ctl.getData()?
    @updateDate()
    if @ctl.isLastFrame()
      @updatePlayButton 'last'
    else
      @updatePlayButton if @ctl.interval? then 'stop' else 'play'

  onUpdateData: -> @update true

  # event handlers
  selectDate: ->
    @ctl.setTime Date.YMDH parseInt(@selY.value()), parseInt(@selM.value()),
                           parseInt(@selD.value()), parseInt(@selH.value())

  buttonPrevY: -> @ctl.setTime @ctl.getTime().prevYear()
  buttonNextY: -> @ctl.setTime @ctl.getTime().nextYear()
  buttonPrevM: -> @ctl.setTime @ctl.getTime().prevMon()
  buttonNextM: -> @ctl.setTime @ctl.getTime().nextMon()
  buttonPrevD: -> @ctl.setTime @ctl.getTime().prevDay()
  buttonNextD: -> @ctl.setTime @ctl.getTime().nextDay()
  buttonPrevH: -> @ctl.setTime @ctl.getTime().prevHour()
  buttonNextH: -> @ctl.setTime @ctl.getTime().nextHour()

  buttonPlay: ->
    if @ctl.interval?
      @weatherView.stop()
      @updatePlayButton 'play'
    else
      @weatherView.play()
      @updatePlayButton 'stop'

  selectA: ->
    @weatherView.setOption 'a', parseInt @selA.value()

  radioC: (i) ->        # PC only
    c = CIRCLE_TYPE[i]
    @weatherView.setOption 'c', c
    @disp.setGrad c

  selectC: ->           # Mobile only
    c = @selC.value()
    @weatherView.setOption 'c', c
    @disp.setGrad c

  selectS: ->
    sz = parseInt @selS.value()
    @weatherView.setOption 's', sz
    @radC.enable sz != 0
    @disp.setGrad if sz != 0 then @option.c else null

  selectW: ->
    sz = parseInt @selW.value()
    @weatherView.setOption 'w', sz

  updatePlayButton: (state) ->
    switch state
      when 'play', 'last'
        @play.enable(state == 'play')
             .setText('&nbsp;再生&nbsp;')
             .setHighlight('regular')
      when 'stop'
        @play.enable(true)
             .setText('&nbsp;停止&nbsp;')
             .setHighlight('highlight')

  saveURL: ->
    map = @weatherView.getMap()
    center = map.getCenter()
    window.location.hash = '#' +
      "ll=#{center.lat().toFixed 5},#{center.lng().toFixed 5}&" +
      "z=#{map.getZoom()}&t=#{map.getMapTypeId()}&" +
      "d=#{@dateQueryString()}&a=#{@option.a}&" +
      "c=#{@option.c}&s=#{@option.s}&w=#{@option.w}&" +
      @infoView.getQuery()

  showInfo: (id) -> @infoView.showPlace id

  closeInfo: -> @weatherView.eraseMarker()

window.WeatherControlView = WeatherControlView
