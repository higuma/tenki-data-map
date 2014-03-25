PATH_INFO = 'PATH_INFO'

class CsvSwitch
  DOT_CSV = '.csv'
  EMPTY = ''
  SLASH = '/'
  INDEX_HTML = '/index.html'

  def initialize(app, appCsv)
    @app = app
    @appCsv = appCsv
  end

  def call(env)
    path = env[PATH_INFO]
    env[PATH_INFO] = INDEX_HTML if path == SLASH || path == EMPTY
    if path[-4, 4] == DOT_CSV
      @appCsv.call env
    else
      @app.call env
    end
  end
end

class CsvGzServer
  HTTP_ACCEPT_ENCODING = 'HTTP_ACCEPT_ENCODING'
  GZIP = 'gzip'
  DOT_GZ = '.gz'
  CONTENT_TYPE = 'Content-Type'
  CONTENT_ENCODING = 'Content-Encoding'
  CONTENT_LENGTH = 'Content-Length'
  TEXT_CSV = 'text/csv'

  def initialize(file)
    @file = file
  end

  def call(env)
    env[PATH_INFO] += DOT_GZ
    res = @file.call env
    if res[0] == 200
      hdr = res[1]
      hdr[CONTENT_TYPE] = TEXT_CSV
      if (enc = env[HTTP_ACCEPT_ENCODING]) && enc.include?(GZIP)
        hdr[CONTENT_ENCODING] = GZIP
      else
        Zlib::GzipReader.open res[2].to_path do |gz|
          hdr.delete CONTENT_ENCODING
          hdr.delete CONTENT_LENGTH
          res[2] = [gz.read]
        end
      end
    end
    res
  end
end

run CsvSwitch.new(
  Rack::Deflater.new(
    Rack::File.new 'public'
  ),
  CsvGzServer.new(
    Rack::File.new 'public'
  )
)
