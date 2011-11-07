util = require 'util'

levels =
  panic: 0
  error: 1
  warn: 2
  info: 3
  debug: 4
  trace: 5

middleware = {}

middleware.formatter = (formatstring=null) ->
  defaultFormat = "%timestamp %message "
  formatstring ||= defaultFormat

  (entry) ->
    entry.message = formatstring + entry.message

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

dfltM = [ middleware.formatter(), middleware.inspector() ]
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
    entry = {timestamp: new Date(), message, logger: @, params}
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
    logger = new Logger(options)
    logger._middleware = @_middleware
    logger._outputters = @_outputters
    logger

module.exports = defaultLogger = new Logger
