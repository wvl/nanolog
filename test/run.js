
var log = require('../')

log.info("You can use it straight out of the box");

log.I("I Shortcut")

var warnlogger = log.create({level: 'warn'})
warnlogger.info("This should not log")
warnlogger.warn("This should log")

log.info("You can display objects as well", {msg: "Hello World"})

log.to(log.out.stderr())
log.info("This should now be sent to stderr and only stderr")

dup = log.dup({level: 'warn'})
dup.warn("Dup should now send stuff to stderr")
dup.info("But not info")

log.set({modules: {feature: 'debug', feature2: 'warn'}})

var feat = log.module("feature")
feat.debug("feature debug: not blank")

var feat2 = log.module("feature2")
feat2.info("feature2 info: blank")

var feat3 = log.module("feature3")
feat3.info("module will behave as normal, If not overriden")
feat3.debug("so this won't be shown")

log.info("this should not be blank")

var newlog = log.create()
newlog.use(log.m.formatter("%timestamp% [%level%] %message%", 
                            {timestamp: function(date) { return date.getFullYear(); }}))
newlog.info("This should have a timestamp, formatted as full year")

