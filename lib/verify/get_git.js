var exec = require('../spawn-git.js')

var helper = require('../helpers.js')
var userData = require('../user-data.js')

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
  exec('config user.email', function (err, stdout, stderr) {
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
      exec('config user.name', function (err, stdout, stderr) {
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
          exec('--version', function (err, stdout, stdrr) {
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
