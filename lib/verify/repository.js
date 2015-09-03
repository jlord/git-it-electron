var exec = require('../spawn-git.js')
var fs = require('fs')

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

// do I want to do this as a var? un-needed, also can't browser view
// pass in the challenge string?
var currentChallenge = 'repository'

module.exports = function repositoryVerify (path) {
  // path should be a directory
  if (!fs.lstatSync(path).isDirectory()) {
    addToList('Path is not a directory', false)
    return helper.challengeIncomplete()
  }
  exec('status', {cwd: path}, function (err, stdout, stdrr) {
    if (err) {
      addToList('This folder is not being tracked by Git.', false)
      return helper.challengeIncomplete()
    }
    // can't return on error since git's 'fatal' not a repo is an error
    // potentially read file, look for '.git' directory
    var status = stdout.trim()
    if (status.match('On branch')) {
      addToList('This is a Git repository!', true)
      markChallengeCompleted(currentChallenge)
      userData.updateData(currentChallenge)
    }
    else {
      addToList("This folder isn't being tracked by Git.", false)
      helper.challengeIncomplete()
    }
  })
}
