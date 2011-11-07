#!/usr/bin/env node

var fs = require('fs');
var path = require('path');
var exec = require('child_process').exec;
var l = function(dir) { return path.join(__dirname, dir); }

exec('node '+l('./run.js')+' >'+l('stdout')+' 2>'+l('stderr'),
  function(err, stdout, stderr) {
    matches('stdout');
    matches('stderr');
  }
);

function matches(what) {
  exec('diff -u '+l(what) + ' ' + l(what+'.expected'),
    function(err, stdout, stderr) {
      if (stdout=="") {
        console.log("OK: "+what);
      } else {
        console.log("FAIL: "+what);
        console.log(stdout);
      }
    }
  );
};
