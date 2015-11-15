fs   = require 'fs'
path = require 'path'
http = require 'http'
zlib = require 'zlib'

MimeType =
  html: 'text/html'
  js:   'text/javascript'
  css:  'text/css'
  csv:  'text/csv'

ErrorResponse =
  EACCES:  [403, 'Forbidden']
  ENOENT:  [404, 'Not Found']
  DEFAULT: [500, 'Internal server error']

RootPath = 'public'

serveFile = (res, url, mime) ->
  stream = fs.createReadStream url
  stream.on 'error', (err) ->
    errRes = ErrorResponse[err.code] || ErrorResponse.DEFAULT
    res.writeHead errRes[0], 'Content-Type': 'text/plain'
    res.end "#{errRes[0]} #{errRes[1]}"
    return
  res.writeHead 200, 'Content-Type': mime
  stream.pipe res
  return

serveGzFile = (res, url, gzipSupported) ->
  # console.log url
  mime = MimeType[path.extname(url).substr(1)] || 'text/plain'
  url = RootPath + url
  urlGz = url + '.gz'
  headers = 'Content-Type': mime
  if gzipSupported
    stream = fs.createReadStream urlGz
    stream.on 'error', (err) ->
      serveFile res, url, mime
      return
    headers['Content-Encoding'] = 'gzip'
    res.writeHead 200, headers
    stream.pipe res
  else
    fs.readFile urlGz, (err, data) ->
      if err?
        serveFile res, url, mime
      else
        zlib.gunzip data, (err, result) ->
          if err?
            errRes = ErrorResponse.DEFAULT      # 500: internal server error
            res.writeHead errRes[0], 'Content-Type': 'text/plain'
            res.end "#{errRes[0]} #{errRes[1]}"
          else
            res.writeHead 200, headers
            res.end result
      return
  return

server = http.createServer (request, res) ->
  url = request.url
  url = '/index.html' if url == '/'
  enc = request.headers['accept-encoding']
  serveGzFile res, url, enc? && enc.indexOf('gzip') != -1
  return

port = Number(process.env.PORT || 8888)
server.listen port
console.log "listening on port #{port}"
