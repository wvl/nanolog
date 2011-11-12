
var log = require('../')

log.info("You can use it straight out of the box");
log.I("I Shortcut")
log.info("You can display objects as well", {msg: "Hello World"})
log.warn("uh oh")
log.debug("Not displaying debug right now")

// You can set the default output level, and even the default log levels:
log.set({levels: {bad: 0, good: 1, boring: 2}, level: 'good'})
log.bad("Uh Oh")
log.good("better")
log.boring("Not logged")
log.set({levels: log.defaults.levels, level: 'debug'})
log.error("reset")
log.debug("Now debug level")

// We can customize the output format
log.to(log.out.stdout({format: "nanolog: %message%"}))
log.info("Displays with custom format")
log.to(log.out.stdout({format: "%message%"}), 
       log.out.stderr({format: "stderr: %message%"}))
log.info("Sent to both stdout and stderr")

// We can set our own log entry attributes:
log.attrs.upcaseMessage = function(entry) {
  return entry.get('message').toUpperCase();
}
log.to(log.out.stdout({format: "%upcaseMessage%"}))
log.info("hello, world")

// We can create a new logger
var warnlogger = log.create({level: 'warn'})
warnlogger.info("This should not log")
warnlogger.warn("This should log")

// We can dup a logger
log2 = log.dup()
log2.debug("log2 should log debug")

log.to(log.out.stdout())
log.set({level: 'info'})
log.info("Back to normal log")

log.to(log.out.stdout({format: "%module%: %message%"}))
var feat = log.module("feature")
feat.debug("feature debug: blank")
feat.error("feature error: not blank")
log.set({modules: {feature: 'debug', base: 'error'}})
feat.D("feature debug: should log")

var feat2 = log.module("feature3")
feat2.info("module will behave as normal, If not overriden")
feat2.debug("so this won't be shown")

var namespaced = log.module("base::feature5")
namespaced.info("using the module namespace should not display")

log.info("base logger again")

// Override log levels at the output level
log.to(log.out.stdout({level: 'debug'}), log.out.stderr({level: 'warn'}))
log.info("Should log to stdout")
log.warn("Should log to stdout and stderr")

// File test
log.to(log.out.file({filename: './test.log'}))
log.info("This should go to the log")
log.warn("This warning should be written")
log.debug("This should not log")
