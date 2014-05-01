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
  stream = fs.createReadStream url + '.gz'
  stream.on 'error', (err) ->
    serveFile res, url, mime
    return
  headers = 'Content-Type': mime
  if gzipSupported
    headers['Content-Encoding'] = 'gzip'
    res.writeHead 200, headers
    stream.pipe res
  else
    res.writeHead headers
    stream.pipe(zlib.createUnzip()).pipe(res)
  return

server = http.createServer (request, res) ->
  url = request.url
  url = '/index.html' if url == '/'
  enc = request.headers['accept-encoding']
  serveGzFile res, url, enc? && enc.indexOf('gzip') != -1
  return

server.listen Number(process.env.PORT || 8888)
