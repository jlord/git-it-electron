#!/usr/bin/env node

var exec = require('child_process').exec
var fs = require('fs')

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'remote_control'

// check that they've made a push

module.exports = function verifyRemoteControlChallenge (path) {
  if (!fs.lstatSync(path).isDirectory()) return addtoList('Path is not a directory', false)
  exec('git reflog show origin/master', {cwd: path}, function (err, stdout, stderr) {
    if (err) {
      addtoList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var ref = stdout.trim()

    if (ref.match('update by push')) {
      addtoList('Bingo! Detected a push.', true)
      markChallengeCompleted(currentChallenge)
      userData.updateData(currentChallenge)
    }
    else {
      addtoList('No evidence of push.', false)
      helper.challengeIncomplete()
    }
  })
}
