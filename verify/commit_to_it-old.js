var exec = require('child_process').exec
var fs = require('fs')

var helper = require('../verify/helpers.js')
var userData = require('../data.json')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted
var writeData = helper.writeData

var currentChallenge = 'commit_to_it'

// check that they've commited changes

module.exports = function commitVerify (path) {
  exec('git status', {cwd: path}, function (err, stdout, stdrr) {
    if (err) return addtoList(err.message, false)
    var show = stdout.trim()

    if (show.match("nothing to commit")) {
      addtoList("Changes have been committed!", true)
    }
    else if (show.match("Changes not staged for commit")){
      addtoList("Seems there are still change to commit.", false)
    } else addtoList("Hmm, can't find committed changes.", false)
  })
}
