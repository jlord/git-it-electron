#!/usr/bin/env node
// @flow

var request = require('request')
var path = require('path')
var exec = require('../../lib/spawn-git.js')
var helper = require('../../lib/helpers.js')
var userData = require('../../lib/user-data.js')
var os = require('os')

var url = 'http://reporobot.jlord.us/collab?username='

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'its_a_small_world'

module.exports = function verifySmallWorldChallenge () {
  // don't need this cwd, but hacking this in to make flow happy
  exec('config user.username', { cwd: os.homedir() }, function (err, stdout, stdrr) {
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
          // If they have a non 200 error, log it so that we can  use
          // devtools to help user debug what went wrong
          if (body.error) console.log('StausCode:', response.statusCode, 'Body:', body)
          addToList("Reporobot doesn't have access to the fork", false)
          helper.challengeIncomplete()
        }
      }
    })
  }
}
