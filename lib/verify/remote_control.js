#!/usr/bin/env node
// @flow

var fs = require('fs')
var path = require('path')
var exec = require('../../lib/spawn-git.js')
var helper = require('../../lib/helpers.js')
var userData = require('../../lib/user-data.js')

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'remote_control'

// check that they've made a push

module.exports = function verifyRemoteControlChallenge (path: string) {
  if (!fs.lstatSync(path).isDirectory()) {
    addToList('Path is not a directory', false)
    return helper.challengeIncomplete()
  }
  exec('reflog show origin/master', {cwd: path}, function (err, stdout, stderr) {
    if (err) {
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var ref = stdout.trim()

    if (ref.match('update by push')) {
      addToList('Bingo! Detected a push.', true)
      markChallengeCompleted(currentChallenge)
      userData.updateData(currentChallenge)
    } else {
      addToList('No evidence of push.', false)
      helper.challengeIncomplete()
    }
  })
}
