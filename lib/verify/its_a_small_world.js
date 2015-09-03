#!/usr/bin/env node

var request = require('request')
var exec = require('child_process').exec

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var url = 'http://reporobot.jlord.us/collab?username='

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'its_a_small_world'

module.exports = function verifySmallWorldChallenge () {
  exec('git config user.username', function (err, stdout, stdrr) {
    if (err) {
      addToList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    var username = stdout.trim()
    collaborating(username)
  })

  // check that they've added RR as a collaborator

  function collaborating (username) {
    request(url + username, {json: true}, function (err, response, body) {
      if (err) {
        addToList('Error: ' + err.message, false)
        return helper.challengeIncomplete()
      }
      if (!err && response.statusCode === 200) {
        if (body.collab === true) {
          addToList('Reporobot has been added!', true)
          markChallengeCompleted(currentChallenge)
          userData.updateData(currentChallenge)
        } else {
          addToList("Reporobot doesn't have access to the fork", false)
          helper.challengeIncomplete()
        }
      }
    })
  }
}
