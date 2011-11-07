Sigh, yes, another logging module.

The goals:
  * Flexible -- format of log entry, where to log
  * Simple -- Simple api

### Usage

The default logger is set to log to stdout, with coloured logs

```js
var llog = require('llog');
llog.info("My Message")
llog.error("Log my error")
llog.debug("Debug info", {msg: 'All params are output'})
```

You can also customize the logger:

```js
var llog = require('llog');
llog.use(llog.m.color(), llog.m.git())

formatstring = "%(white|bold)timestamp% [%(color)level%] %(color)message%"
llog.use(llog.m.formatter(formatstring)

llog.to(llog.outputs.stdout(), llog.outputs.file('./log.txt'))

llog.set({level: 'info'})
```

By default, all operations work on the default logger that is returned
from the `llog` module. You can create other loggers as well:

```js
var llog = require('llog');
var filelog = llog.create('filelog');
filelog.to.file('./log.txt');
filelog.info("This goes to the log file");
````

Finally, you can drill down and be specific about what gets output by
using the `module` feature.

```js
var llog = require('llog');
llog.set({modules: {feature: 'debug', root: 'info'})

var featureLogger = llog.module('feature');
var rootLogger = llog.module('root');

llog.info("You can set module level overrides on output level");
featureLogger.debug("This will be displayed");
rootLogger.debug("This will not be displayed");
```

API
===

### set

Set new options on the logger.

levels: An object, keys are level name, value is the integer level.

  Default:
    {'panic': 0, 'error': 1, 'warn': 2, 'info': 3, 'debug': 4, 'trace':
5}

level: Level to log at, default: 'info'

### use

Adds middleware to the chain.

### to

Adds a different output method to the logger.

### module

Returns a logger object that is module specific. You can then set
module specific logger levels (to turn up/down certain sections of
code).

