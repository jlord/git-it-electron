#!/usr/bin/env node
// @flow

var request = require('request')
var exec = require('../../lib/spawn-git.js')
var helper = require('../../lib/helpers.js')
var userData = require('../../lib/user-data.js')
var os = require('os')

var addToList = helper.addToList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'requesting_you_pull_please'
var url = 'http://reporobot.jlord.us/pr?username='

// check that they've submitted a pull request
// to the original repository jlord/patchwork

module.exports = function verifyPRChallenge () {
  // don't need this cwd, but hacking this in to make flow happy
  exec('config user.username', { cwd: os.homedir() }, function (err, stdout, stdrr) {
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
