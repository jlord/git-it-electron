"use strict";

var helpers = require('./helpers.js')

module.exports = function commitVerify(Path){
  helpers.execute('git status', {cwd: Path}).then(function(Output){
    Output = Output.stdout.trim();
    if(Output.match("nothing to commit")){
      helpers.addToList("Changes have been committed!", true)
    } else if(Output.match("Changes not staged for commit")){
      return Promise.reject("Seems there are still change to commit.")
    } else {
      return Promise.reject("Hmm, can't find committed changes.")
    }
  }).then(function() {
    Progress.commit_to_it = true
  }).catch(function(Error){
    helpers.addToList(Error, false)
  })
}