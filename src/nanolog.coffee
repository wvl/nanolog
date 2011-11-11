util = require 'util'

defaults = {}
defaults.levels = {
  panic: 0, error: 1, warn: 2, info: 3, debug: 4, trace: 5
}
defaults.level = 'info'

defaults.fileFormat = "%timestamp% [%level%] %message%"
defaults.consoleFormat = "[%(default)level%] %(default)message%%:n:inspect%"

defaults.colors = {
  black: 30, red: 31, green: 32, yellow: 33, blue: 34,
  magenta: 35, cyan: 36, white: 37,
  bold: 1, underline: 4, reversed: 7
}

defaults.colorMap = {
  info: 'white', debug: 'cyan', warn: 'yellow', error: 'red'
}

middleware = m = {}

middleware.color = (map=defaults.colorMap, colors=defaults.colors, defaultColor='white') ->
  fn = (entry) ->
    map[entry.level] || defaultColor
  fn.colors = colors
  fn

middleware.inspector = (type='inspect') ->
  types =
    inspect: (param) -> util.inspect(param)
    json: (param) -> JSON.stringify(param, null, '  ')

  (entry) ->
    entry.get('params').map((param) -> types[type](param)).join('\n')

middleware.datetime = ->
  (entry) ->
    d = new Date()
    "#{d.getFullYear()}#{d.getMonth()+1}#{d.getDate()} "+
    "#{d.getHours()}:#{d.getMinutes()}:#{d.getSeconds()}"

outputters =
  stdout: (opts={}) ->
    opts.format ||= defaults.consoleFormat

    (entry) ->
      if !opts.level || entry.logger.shouldLog(entry.level, opts.level)
        console.log entry.format(opts.format)

  stderr: (opts={}) ->
    opts.format ||= defaults.consoleFormat

    (entry) ->
      if !opts.level || entry.logger.shouldLog(entry.level, opts.level)
        util.debug entry.format(opts.format)

defaults.attrs =
  timestamp: -> new Date().getTime()
  datetime: -> m.datetime()
  inspect: m.inspector()
  color: m.color()

defaults.outputs = [outputters.stdout()]

esc = (str) ->
  "\x1B["+str+'m'

class Entry
  constructor: (@logger, @level, @message, @params) ->

  get: (param) ->
    if @logger.attrs[param] then @logger.attrs[param](@) else @[param]

  # The format string is a simple substitution format.
  # Attributes to replace are wrapped with '%'.
  #   %message%
  #
  # Optional colors are specified by prefacing with parentheses 
  # containing either the color name, or 'default':
  #   %(red)timestamp% %(default)message%
  #
  # You can prefix the attribute with space using 'n','s', or 't'.
  #   n -> newline
  #   s -> space
  #   t -> tab
  # This is useful for optional attributes:
  #   %:n:inspect%
  #
  format: (formatstring) ->
    # %(color):nss:param%
    formatstring.replace /%(\(([\w,]+)\))?(:([snt]+):)?(\w+)%/g,
      (str, p1, color, p3, space, param, offset, s) =>
        r = @get(param)
        if color and @get('color')
          colors = @logger.attrs['color'].colors
          r = esc(colors[if color=='default' then @get('color') else color])+r+esc(0)
        if space and r
          r = space.replace(/n/g, '\n').replace(/s/g, ' ').replace(/t/g, '\t')+r
        r

class Logger
  constructor: (options={}, @attrs=defaults.attrs, @_outputs=defaults.outputs) ->
    for key,val of {levels: defaults.levels, level: defaults.level, modules: {}}
      options[key] = val unless options[key]
    @_opts={}
    @set(options)

    @defaults = defaults

    @middleware = @m = middleware
    @outputters = @out = outputters

  set: (options) ->
    if options.levels
      # Delete previous log functions
      Object.keys(@_opts.levels || {}).forEach (level) =>
        delete @[level]
        delete @[level[0].toUpperCase()]

      Object.keys(options.levels).forEach (level) =>
        @[level] = (msg, params...) =>
          @_log(level, msg, params...) if @shouldLog(level, @_opts.level)
        first = level[0].toUpperCase()
        @[first] = @[level] unless @[first]
      @_opts.levels = options.levels

    @_opts.modules = options.modules if options.modules
    @_opts.level = options.level if options.level
    @

  shouldLog: (thisLevel, loggableLevel) ->
    @_opts.levels[thisLevel] <= @_opts.levels[loggableLevel]

  # The basic log function with level check
  log: (level, message, params...) ->
    @_log(level, message, params...) if @shouldLog(level, @_opts.level)

  _log: (level, message, params...) ->
    entry = new Entry(@, level, message, params)
    @_outputs.forEach (out) -> out(entry)

  # Set a new array of output functions.
  to: (outputters...) ->
    @_outputs = outputters
    @

  # Create a new logger object that proxies to this class with 
  # additional level check that is specific to the module name.
  module: (module) ->
    moduleLogger = {}
    Object.keys(@_opts.levels).forEach (level) =>
      moduleLogger[level] = (msg, params...) =>
        if @shouldLog(level, @_opts.modules[module] || @_opts.level)
          @_log(level, msg, params...) 
      first = level[0].toUpperCase()
      moduleLogger[first] = moduleLogger[level] unless moduleLogger[first]
    moduleLogger

  # Create a new logger that is a clone of this one.
  dup: (options={}) ->
    logger = new Logger(@_opts, @_attrs, @_outputs)
    # logger.set(options)
    logger

  # Create a new logger instance, using default
  create: (options) ->
    new Logger(options)

module.exports = defaultLogger = new Logger
