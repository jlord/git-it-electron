#!/usr/bin/env node

var exec = require('../spawn-git.js')
var fs = require('fs')

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'forks_and_clones'

// check that they've added the remote, that shows
// that they've also then forked and cloned.

module.exports = function verifyForksAndClonesChallenge (path) {
  if (!fs.lstatSync(path).isDirectory()) {
    addToList('Path is not a directory', false)
    return helper.challengeIncomplete()
  }
  exec('remote -v', {cwd: path}, function (err, stdout, stdrr) {
    if (err) {
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var show = stdout.trim()

    if (show.match('upstream') && show.match('github.com[\:\/]jlord/')) {
      addToList('Upstream remote set up!', true)
      markChallengeCompleted(currentChallenge)
      userData.updateData(currentChallenge)
    } else {
      addToList('No upstream remote matching /jlord/Patchwork.', false)
      helper.challengeIncomplete()
    }
  })
}
