#!/usr/bin/env node

var fs = require('fs')
var path = require('path')
var exec = require(path.join(__dirname, '../../lib/spawn-git.js'))
var helper = require(path.join(__dirname, '../../lib/helpers.js'))
var userData = require(path.join(__dirname, '../../lib/user-data.js'))

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'remote_control'

// check that they've made a push

module.exports = function verifyRemoteControlChallenge (path) {
  if (!fs.lstatSync(path).isDirectory()) {
    addToList('Path is not a directory.', false)
    return helper.challengeIncomplete()
  }
  exec('reflog show origin/master', {cwd: path}, function (err, stdout, stderr) {
    if (err) {
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var ref = stdout.trim()

    if (ref.match('update by push')) {
      addToList('You pushed changes!', true)
      markChallengeCompleted(currentChallenge)
      userData.updateData(currentChallenge)
    } else {
      addToList('No evidence of push.', false)
      helper.challengeIncomplete()
    }
  })
}
