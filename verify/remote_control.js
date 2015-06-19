#!/usr/bin/env node

var exec = require('child_process').exec
var fs = require('fs')

var helper = require('../verify/helpers.js')
var userData = require('../data.json')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted
var writeData = helper.writeData

var currentChallenge = 'remote_control'

// check that they've made a push

module.exports = function verifyRemoteControlChallenge (path) {
  if (!fs.lstatSync(path).isDirectory()) return addtoList('Path is not a directory', false)
  exec('git reflog show origin/master', {cwd: path}, function (err, stdout, stderr) {
    if (err) return addtoList('Error: ' + err.message, false)
    var ref = stdout.trim()

    if (ref.match('update by push')) {
      addtoList('Bingo! Detected a push.', true)
      markChallengeCompleted(currentChallenge)
      writeData(userData, currentChallenge)
    }
    else addtoList('No evidence of push.', false)
  })
}
