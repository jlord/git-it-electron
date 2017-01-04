// @flow

var path = require('path')
var exec = require( '../../lib/spawn-git.js')
var helper = require('../../lib/helpers.js')
var userData = require('../../lib/user-data.js')
var os = require('os')

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'get_git'

var total = 3
var counter = 0

// TODO
// Think about how best to show errors to user
// All that nesting
// Potentially put all responses in array, use length for total

module.exports = function verifyGetGitChallenge () {
  counter = 0
  exec('config user.email', { cwd: os.homedir() }, function (err, stdout, stderr) {
    if (err) {
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var email = stdout.trim()
    if (email === '') {
      addToList('No email found.', false)
      helper.challengeIncomplete()
    } else {
      counter++
      addToList('Email Added', true)
      exec('config user.name',  { cwd: os.homedir() }, function (err, stdout, stderr) {
        if (err) {
          addToList('Error: ' + err.message, false)
          return helper.challengeIncomplete()
        }
        var name = stdout.trim()
        if (name === '') {
          addToList('No name found.', false)
          helper.challengeIncomplete()
        } else {
          counter++
          addToList('Name Added!', true)

          // TODO: we no longer rely on the user having a version of Git installed
          // this check here becomes a self-check, maybe we don't need to do this
          exec('--version',  { cwd: os.homedir() }, function (err, stdout, stdrr) {
            if (err) {
              addToList('Error: ' + err.message, false)
              return helper.challengeIncomplete()
            }
            var gitOutput = stdout.trim()
            if (gitOutput.match('git version')) {
              counter++
              addToList('Found Git installed.', true)
            } else {
              addToList('Found no Git installed.', false)
              helper.challengeIncomplete()
            }
            if (counter === total) {
              markChallengeCompleted(currentChallenge)
              userData.updateData(currentChallenge)
            }
          })
        }
      })
    }
  })
}
