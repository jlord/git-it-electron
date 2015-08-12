#!/usr/bin/env node

var exec = require('child_process').exec

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'pull_never_out_of_date'

// do a fetch dry run to see if there is anything
// to pull; if there is they haven't pulled yet

module.exports = function verifyPullChallenge (path) {
  exec('git fetch --dry-run', function (err, stdout, stdrr) {
    if (err) return addtoList('Error, unexpected response.', false)
    var status = stdout.trim()
    if (!err && status === '') {
      addtoList('Up to date!', true)
      markChallengeCompleted(currentChallenge)
      userData.updateData(currentChallenge)
    }
    else addtoList('There are changes to pull in.', false)
  })
}
