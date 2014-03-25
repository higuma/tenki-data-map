PLACES = Places

WDAY = ['日', '月', '火', '水', '木', '金', '土']

VIEW_TYPES = ['t', 'p', 'w', 's', 'f', 'd', 'l', 'i']

RE_OPT_V = /^([01])$/
RE_OPT_P = /^(\d+)$/
RE_OPT_I = /^([tpwsfdli])$/
RE_OPT_R = /^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d),(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)$/

class InfoView
  constructor: (@frame, @weatherView) ->
    @weatherCtl = @weatherView.ctl
    @weatherCtl.addView @

    @view = @frame.addSubframe()
    @frame.removeChild @view    # view is initially detached
    @attached = false
    @view.addHR()
    row = @view.addRow()
    row.getElement().style.height = "18px"
    @name = row.addStatic '---'
    divR = document.createElement 'div'
    divR.className = 'topRight'
    row.appendChild divR
    new GoogleMapsWidget.Button divR, '&nbsp;閉じる&nbsp;',
                                '情報ビューを閉じる', => @attach false
    row = @view.addRow()
    @radT = row.addRadioGroup (i) => @setViewType VIEW_TYPES[i]
    @radT.add '気温', '気温トレンドグラフを表示'
    @radT.add '降水', '降水量トレンドグラフを表示'
    @radT.add '風速', '風速トレンドグラフを表示'
    @radT.add '日照', '日照時間トレンドグラフを表示'
    @radT.add '降雪', '降雪量トレンドグラフを表示'
    @radT.add '積雪', '積雪量トレンドグラフを表示'
    @radT.add 'データ', '一日分の全データを表示'
    @radT.add '地点情報', '地点情報を表示'
    @radT.finalize(0)

    @contentsFrame = @view.addRow()
    @contents = @graph = new GraphView @
    @data = new DataView @
    @placeInfo = new PlaceInfoView @
    @type = 't'
    @contentsFrame.appendChild @graph
    @graph.onAttach true

  processOption: (option) ->
    attached = type = l = r = null
    if option.v? && (re = option.v.match RE_OPT_V)
      attached = re[1] == '1'
    if option.p? && (re = option.p.match RE_OPT_P)
      @id = id if PLACES[id = parseInt re[1]]?
    if option.i? && (re = option.i.match RE_OPT_I)
      type = re[1]
    if option.r? && (re = option.r.match RE_OPT_R)
      l = Date.YMDHM parseInt(re[1]), parseInt(re[2]), parseInt(re[3]),
                     parseInt(re[4]), parseInt(re[5])
      r = Date.YMDHM parseInt(re[6]), parseInt(re[7]), parseInt(re[8]),
                     parseInt(re[9]), parseInt(re[10])
    @attach attached if attached?
    if @id? && @attached
      @weatherView.showMarker @id
      @showPlace @id
    @graph.setTimeView l, r if l? && r?
    @setViewType type if type?
    return

  attach: (attached) ->
    if attached
      @frame.appendChild @view unless @attached
    else
      @frame.removeChild @view if @attached
      @weatherView.showMarker null
    @attached = attached

  showPlace: (@id) ->
    @attach true
    @updateTitle()
    @contents.onSetPlace()

  update: (sender, success) ->      # sender is always @weatherCtl
    return unless @attached && success
    @updateTitle()
    @contents.update sender, success

  setViewType: (@type) ->
    @radT.select VIEW_TYPES.indexOf @type
    nextContents = switch @type
      when 'l'
        @data
      when 'i'
        @placeInfo
      else
        @graph.setGraph @type
        @graph
    return if @contents == nextContents
    @contents.onAttach false
    @contentsFrame.replaceChild nextContents, @contents
    @contents = nextContents
    @contents.onAttach true
    return

  updateTitle: ->
    title = if (t = @weatherCtl.getTime())?
      "#{t.year()}年#{t.mon()}月#{t.day()}日 (#{WDAY[t.wday()]}) #{t.hour()}時"
    else
      "----年--月--日 --時"
    title += ' &nbsp; '
    p = PLACES[@id]
    title += if p? then p.name else '---'
    @name.setText title
    return

  sNN: (n) -> if n < 10 then "0#{n}" else "#{n}"

  getTimeQuery: (t) ->
    t = new Date t
    "#{t.year()}#{@sNN t.mon()}#{@sNN t.day()}#{@sNN t.hour()}#{@sNN t.min()}"

  getQuery: ->
    q = "v=#{if @attached then '1' else '0'}"
    q += "&p=#{@id}" if @id?
    q += "&i=#{@type}" if @type?
    l = @graph.tL
    r = @graph.tR
    q += "&r=#{@getTimeQuery l},#{@getTimeQuery r}" if l? && r?
    q

window.InfoView = InfoView
