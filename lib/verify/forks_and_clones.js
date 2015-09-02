#!/usr/bin/env node

var exec = require('child_process').exec
var fs = require('fs')

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'forks_and_clones'

// check that they've added the remote, that shows
// that they've also then forked and cloned.

module.exports = function verifyForksAndClonesChallenge (path) {
  if (!fs.lstatSync(path).isDirectory()) {
    addtoList('Path is not a directory', false)
    return helper.challengeIncomplete()
  }
  exec('git remote -v', {cwd: path}, function (err, stdout, stdrr) {
    if (err) {
      addtoList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var show = stdout.trim()

    if (show.match('upstream') && show.match('github.com[\:\/]jlord/')) {
      addtoList('Upstream remote set up!', true)
      markChallengeCompleted(currentChallenge)
      userData.updateData(currentChallenge)
    } else {
      addtoList('No upstream remote matching /jlord/Patchwork.', false)
      helper.challengeIncomplete()
    }
  })
}
