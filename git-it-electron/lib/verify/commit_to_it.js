var fs = require('fs')
var path = require('path')
var exec = require(path.join(__dirname, '../../lib/spawn-git.js'))
var helper = require(path.join(__dirname, '../../lib/helpers.js'))
var userData = require(path.join(__dirname, '../../lib/user-data.js'))

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'commit_to_it'

// check that they've commited changes

module.exports = function commitVerify (path) {
  if (!fs.lstatSync(path).isDirectory()) {
    addToList('Path is not a directory.', false)
    return helper.challengeIncomplete()
  }
  exec('status', {cwd: path}, function (err, stdout, stdrr) {
    if (err) {
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var show = stdout.trim()

    if (show.match('Initial commit')) {
      addToList("Can't find committed changes.", false)
    } else if (show.match('nothing to commit')) {
      addToList('Changes have been committed!', true)
      markChallengeCompleted(currentChallenge)
      userData.updateData(currentChallenge)
    } else {
      addToList('Seems there are changes to commit still.', false)
      helper.challengeIncomplete()
    }
  })
}
