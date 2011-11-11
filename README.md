Sigh, yes, another logging module.

The goals:
  * Flexible -- format of log entry, where to log
  * Simple -- Simple api
  * Multiple output transports, with different configs and log levels

### Usage

The default logger is set to log to stdout, with coloured logs

```js
var log = require('nanolog');
log.info("My Message")
log.error("Log my error")
log.debug("Debug info", {msg: 'All params are output'})
```

You can set the default output level, and even the default log levels:

```js
log.set({levels: {bad: 0, good: 1, boring: 2}, level: 'good'})
log.bad("Uh Oh")
log.boring("Not logged")
```


nanolog uses a stack of output functions to write our logs. You can
set your own with 'to'. You can also set a log level for each output
function that will override the default:

```js
log.to(log.out.stdout(), log.out.file({file: './log.txt', level: 'warn'}))
```

The output functions use a simple substitution format that lets 
you specify what you want your logs to look like:

```js
log.to(log.out.stdout({format: "nanolog: %message%"}))
fmt = "%(white|bold)timestamp% [%(color)level%] %(color)message%"
log.to(log.out.stdout({format: fmt})
```

The logging functionality revolves around a 'LogEntry' object. This
object defines the attributes that can be written. You can easily 
customize the logging functionality by adding functions to this
object. `timestamp`, `datetime`, and `color` are all builtin log
functions that you can use or override.

```js
log.entry.upcaseMessage = function(entry) {
  return entry.get('message').toUpperCase();
}
log.to(log.out.stdout({format: "%upcaseMessage%"}))
log.info("hello, world")
// result:
HELLO, WORLD
```

By default, all operations work on the default logger that is returned
from the `nanolog` module. You can create other loggers as well:

```js
var log = require('nanolog');
var filelog = log.create('filelog');
filelog.to(log.out.file({file: './log.txt'}));
filelog.info("This goes to the log file");
````

Finally, you can drill down and be specific about what gets output by
using the `module` feature.

```js
var log = require('nanolog');
log.set({modules: {feature: 'debug', root: 'info'})

var featureLogger = log.module('feature');
var rootLogger = log.module('root');

log.info("You can set module level overrides on output level");
featureLogger.debug("This will be displayed");
rootLogger.debug("This will not be displayed");
```


API
===

### set

Set new options on the logger.

*levels*: An object, keys are level name, value is the integer level.

  Default:
    {'panic': 0, 'error': 1, 'warn': 2, 'info': 3, 'debug': 4, 'trace':
5}

*level*: `string` level to log at, default: 'info'

*modules*: An object providing custom log levels for modules:

  Example:
    {feature1: 'debug', noisyFeature: 'warn'}

### attrs

`attrs` is an object on the logger. It's keys are functions that can
provide custom data to the output function. By default, attrs is
configured with a number of useful functions:

The entry object starts with the attributes provided by the log
functions:

  * message: The first parameter given to the log function.
  * params: An array of any other parameters passed
  * level: The level of the requested log function

By default attrs is configured with a number of useful functions:

  * timestamp:
  * datetime: provide a formatted datetime value
  * inspect: outputs any additional parameters, using util.inspect
  * color: The default color for the level.

Custom attrs can be provided (or the defaults overriden). Example:

```js
log.entry.upcaseMessage = function(entry) {
  return entry.get('message').toUpperCase();
}
```

### to <list of parameters that contain log function>

Sets the output stack:

```js
log.to(log.out.stdout(), log.out.file({file: './log.txt', level:
'warn'}))
```


### module

Returns a logger object that is module specific. You can then set
module specific logger levels (to turn up/down certain sections of
code).


TODO
----

* Give modules namespaces, so you can control output level more easily:

```js
var I = log.module("mymod::feature1").info;
// then, silence all modules from 'mymod':
log.set({modules: {'mymod': 'error'}});
```

* Add module name to entry hash.
* Add File outputter
* Publish to npm.
