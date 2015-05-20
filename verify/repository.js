"use strict";

var helpers = require('./helpers.js')

module.exports = function commitVerify(Path){
  helpers.execute('git status', {cwd: Path}).then(function(Output){
    if(Output.stderr.length) return Promise.reject(Output.stderr)
    Progress.repository = true
    helpers.addToList("This is a Git repository!", true)
  }).catch(function(Error){
    helpers.addToList(Error, false)
  })
}