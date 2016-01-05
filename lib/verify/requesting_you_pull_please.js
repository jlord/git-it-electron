#!/usr/bin/env node

var exec = require('../spawn-git.js')
var request = require('request')

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'requesting_you_pull_please'
var url = 'http://reporobot.jlord.us/pr?username='

// check that they've submitted a pull request
// to the original repository jlord/patchwork

module.exports = function verifyPRChallenge () {
  exec('config user.username', function (err, stdout, stdrr) {
    if (err) {
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var username = stdout.trim()
    pullrequest(username)
  })

  function pullrequest (username) {
    request(url + username, {json: true}, function (err, response, body) {
      if (!err && response.statusCode === 200) {
        var pr = body.pr
        if (pr) {
          addToList('Found your pull request!', true)
          markChallengeCompleted(currentChallenge)
          userData.updateData(currentChallenge)
        } else {
          // TODO give user url to their repo also
          addToList('No merged pull request found for ' + username +
                    '. If you did make a pull request, return to ' +
                    'its website to see comments.', false)
          helper.challengeIncomplete()
        }
      }
    })
  }
}
