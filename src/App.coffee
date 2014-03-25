# parse option and analize Google maps settings
option = OptionParser.parseUrlOption()
gmOption = OptionParser.processGoogleMapsOption option

# create map
map = new google.maps.Map document.getElementById('map'),
  minZoom: gmOption.ZoomMin
  maxZoom: gmOption.ZoomMax
  zoom: gmOption.zoom
  mapTypeId: gmOption.type
  center: new google.maps.LatLng gmOption.lat, gmOption.lon
  scaleControl: true

# create weather overlay + control view
if Modernizr.inlinesvg
  view = new WeatherView 'map', map, option
  window.onhashchange = => view.onHashChange()
else
  frame = $("<div class='tenki-alert'>
<p>天気データマップの実行にはインラインSVGをサポートするブラウザが必要です(このブラウザでは動作しません)。</p>
<p><a id='aboutThisApplication' href='https://github.com/higuma/tenki-data-map'>天気データマップについて...</a></p>
</div>")[0]
  frame.index = 1
  map.controls[google.maps.ControlPosition.TOP_CENTER].push frame
