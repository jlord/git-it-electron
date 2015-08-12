var exec = require('child_process').exec

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addToList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'get_git'

var total = 3
var counter = 0

// TODO
// Think about how best to show errors to user
// All that nesting
// Potentially put all responses in array, use length for total

module.exports = function verifyGetGitChallenge () {
  exec('git config user.email', function (err, stdout, stderr) {
    if (err) return addToList('An error verifying! Try again.', false)
    var email = stdout.trim()
    if (email === '') {
      addToList('No email found.', false)
    } else {
      counter++
      addToList('Email Added', true)
      exec('git config user.name', function (err, stdout, stderr) {
        if (err) return addToList('An error verifying! Try again.', false)
        var name = stdout.trim()
        if (name === '') {
          addToList('No name found.', false)
        } else {
          counter++
          addToList('Name Added!', true)
          exec('git --version', function (err, stdout, stdrr) {
            if (err) return addToList('An error verifying! Try again.', false)
            var gitOutput = stdout.trim()
            if (gitOutput.match('git version')) {
              counter++
              addToList('Found Git installed.', true)
            } else {
              addToList('Found no Git installed.', false)
            }
            if (counter === total) {
              counter = 0
              markChallengeCompleted(currentChallenge)
              userData.updateData(currentChallenge)
            }
          })
        }
      })
    }
  })
}
