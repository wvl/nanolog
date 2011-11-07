
var llog = require('../')

llog.info("You can use it straight out of the box");

llog.I("I Shortcut")

var warnlogger = llog.create({level: 'warn'})
warnlogger.info("This should not log")
warnlogger.warn("This should log")

llog.info("You can display objects as well", {msg: "Hello World"})

llog.to(llog.out.stderr())
llog.info("This should now be sent to stderr and only stderr")

dup = llog.dup({level: 'warn'})
dup.warn("Dup should now send stuff to stderr")
dup.info("But not info")

llog.set({modules: {feature: 'debug', feature2: 'warn'}})

var feat = llog.module("feature")
feat.debug("feature debug: not blank")

var feat2 = llog.module("feature2")
feat2.info("feature2 info: blank")

var feat3 = llog.module("feature3")
feat3.info("module will behave as normal, If not overriden")
feat3.debug("so this won't be shown")

llog.info("this should not be blank")

var newlog = llog.create()
newlog.use(llog.m.formatter("%timestamp% [%level%] %message%", 
                            {timestamp: function(date) { return date.getFullYear(); }}))
newlog.info("This should have a timestamp, formatted as full year")

