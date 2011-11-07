util = require 'util'

levels =
  panic: 0
  error: 1
  warn: 2
  info: 3
  debug: 4
  trace: 5

middleware = {}

defaultFormat = "%(green)timestamp% [%(default)level%] %message%"
defaultFormat = "[%(default)level%] %(default)message%"

middleware.formatter = (format=defaultFormat, formatFns={}) ->
  defaultFormatFns =
    timestamp: (date) ->
      "#{date.getFullYear()}#{date.getMonth()+1}#{date.getDate()} "+
      "#{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"

  (entry) ->
    entry.message = format.replace /%(\(([\w,]+)\))?(\w+)%/g,
      (str, p1, p2, p3, offset, s) ->
        fn = formatFns[p3] || defaultFormatFns[p3]
        result = if fn then fn(entry[p3]) else entry[p3]
        if p2 and entry.color
          esc(entry.colors[if p2=='default' then entry.color else p2])+result + esc(0)
        else
          result

esc = (str) ->
  "\x1B["+str+'m'

defaultColors = {
  black: 30, red: 31, green: 32, yellow: 33, blue: 34,
  magenta: 35, cyan: 36, white: 37,
  bold: 1, underline: 4, reversed: 7
}

colorMap = {info: 'white', debug: 'cyan', warn: 'red', error: 'red'}

middleware.color = (map = colorMap, colors = defaultColors) ->
  (entry) ->
    entry.color = map[entry.level] || 'white'
    entry.colors = colors
    entry.colorMap = map

middleware.inspector = (type='inspect') ->
  types =
    inspect: (param) -> util.inspect(param)
    json: (param) -> JSON.stringify(param, null, '  ')

  (entry) ->
    entry.params.forEach (param) ->
      entry.message += "\n"+types[type](param)


outputters =
  stdout: (opts={}) ->
    (entry) ->
      console.log entry.message

  stderr: (opts={}) ->
    (entry) ->
      util.debug entry.message

dfltM = [ middleware.color(), middleware.formatter(), middleware.inspector() ]
dfltO = [ outputters.stdout() ]

class Logger
  constructor: (options={}, @_middleware=dfltM, @_outputters=dfltO) ->
    for key,val of {levels, level: 'info', modules: {}}
      options[key] = val unless options[key]
    @_opts={}
    @set(options)

    @middleware = @m = middleware
    @outputters = @out = outputters

    @_origMiddleware = true
    @_origOutputters = true

  set: (options) ->
    if options.levels
      Object.keys(@_opts.levels || {}).forEach (level) =>
        delete @[level]
      Object.keys(options.levels).forEach (level) =>
        @[level] = (msg, params...) ->
          @log(level, msg, params...)
        first = level[0].toUpperCase()
        @[first] = @[level] unless @[first]
      @_opts.levels = options.levels

    @_opts.modules = options.modules if options.modules
    @_opts.level = options.level if options.level
    @

  # The basic log function
  log: (level, message, params...) ->
    if @_opts.levels[level] <= @_opts.levels[@_opts.level]
      @_log(level, message, params...)

  _log: (level, message, params...) ->
    entry = {timestamp: new Date(), message, logger: @, params, level}
    @_middleware.forEach (middleware) ->
      middleware(entry)
    @_outputters.forEach (outputter) ->
      outputter(entry)

  # Append middleware to the queue. If `use` has not been called
  # yet, the list will be reset, in order to override the default.
  use: (middlewares...) ->
    [@_origMiddleware,@_middleware] = [false,[]] if @_origMiddleware
    middlewares.forEach (ware) =>
      @_middleware.push(ware)
    @

  # Append outputters to the queue. If to has not been called yet,
  # the list will be reset, in order to override the default.
  to: (outputters...) ->
    [@_origOutputters,@_outputters] = [false,[]] if @_origOutputters
    outputters.forEach (outputter) =>
      @_outputters.push(outputter)
    @

  module: (module) ->
    moduleLogger = {}
    Object.keys(@_opts.levels).forEach (level) =>
      moduleLogger[level] = (msg, params...) =>
        if @_opts.levels[level] <= @_opts.levels[@_opts.modules[module] || @_opts.level]
          @_log(level, msg, params...) 
      first = level[0].toUpperCase()
      moduleLogger[first] = moduleLogger[level] unless moduleLogger[first]
    moduleLogger

  # Return a logger that is a clone of this one.
  dup: (options) ->
    logger = new Logger(@_opts, @_middleware, @_outputters)
    logger.set(options)

  create: (options) ->
    new Logger(options)

module.exports = defaultLogger = new Logger
