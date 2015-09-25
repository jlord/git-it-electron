var exec = require('../spawn-git.js')
var checks = require('../chal-checks.js')
var userData = require('../user-data.js')

var postResult = checks.postResult
var markChallengeCompleted = checks.markChallengeCompleted

var challengeName = 'get_git'

var total = 3
var counter = 0

// TODO
// Think about how best to show errors to user
// like maybe also put something in the console so that when they open an
// issue about the error you can ask to see it and it will provide more
// detail to you than the short summary you give them
// All that nesting
// Potentially put all responses in array, use length for total

module.exports = function verifyGetGitChallenge () {
  counter = 0
  exec('config user.email', function (err, stdout, stderr) {
    if (err) {
      postResult('Error: ' + err.message, false)
      return checks.challengeIncomplete()
    }
    var email = stdout.trim()
    if (email === '') {
      postResult('No email found.', false)
      checks.challengeIncomplete()
    } else {
      counter++
      postResult('Email Added', true)
      exec('config user.name', function (err, stdout, stderr) {
        if (err) {
          postResult('Error: ' + err.message, false)
          return checks.challengeIncomplete()
        }
        var name = stdout.trim()
        if (name === '') {
          postResult('No name found.', false)
          checks.challengeIncomplete()
        } else {
          counter++
          postResult('Name Added!', true)
          exec('--version', function (err, stdout, stdrr) {
            if (err) {
              postResult('Error: ' + err.message, false)
              return checks.challengeIncomplete()
            }
            var gitOutput = stdout.trim()
            if (gitOutput.match('git version')) {
              counter++
              postResult('Found Git installed.', true)
            } else {
              postResult('Found no Git installed.', false)
              checks.challengeIncomplete()
            }
            if (counter === total) {
              markChallengeCompleted(challengeName)
              userData.updateData(challengeName)
            }
          })
        }
      })
    }
  })
}
