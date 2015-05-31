#!/usr/bin/env node

var exec = require('child_process').exec

var helper = require('../verify/helpers.js')
var userData = require('../data.json')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted
var writeData = helper.writeData

var currentChallenge = 'remote_control'

// check that they've made a push

module.exports = function verifyRemoteControlChallenge () {
  exec('git reflog show origin/master', function (err, stdout, stderr) {
    if (err) return addtoList('Error: ' + err.message, false)
    var ref = stdout.trim()

    if (ref.match('update by push')) {
      addtoList('Bingo! Detected a push.', true)
      markChallengeCompleted()
      writeData(userData, currentChallenge)
    }
    else addtoList('No evidence of push.', false)
  })
}
