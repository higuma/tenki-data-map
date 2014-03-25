class CsvParser
  constructor: (input) ->
    @data = input.split ','

  get_i: ->
    s = @data.shift()
    if s.length == 0 then null else parseInt s

  get_f: ->
    s = @data.shift()
    if s.length == 0 then null else parseFloat s

window.CsvParser = CsvParser
