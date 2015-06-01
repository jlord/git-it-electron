#!/usr/bin/env node

var exec = require('child_process').exec
var request = require('request')

var helper = require('../verify/helpers.js')
var userData = require('../data.json')

var addtoList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted
var writeData = helper.writeData

var currentChallenge = 'requesting_you_pull_please'

var url = 'http://reporobot.jlord.us/pr?username='

// check that they've submitted a pull request
// to the original repository jlord/patchwork

module.exports = function verifyPRChallenge () {
  exec('git config user.username', function (err, stdout, stdrr) {
    if (err) return addtoList('Error: ' + err.message, false)
    var username = stdout.trim()
    pullrequest(username)
  })

  function pullrequest (username) {
    request(url + username, {json: true}, function (err, response, body) {
      if (!err && response.statusCode === 200) {
        var pr = body.pr
        if (pr) {
          addtoList('Found your pull request!', true)
          markChallengeCompleted()
          writeData(userData, currentChallenge)
        } else {
          addtoList('No merged pull request found for ' + username
                       + '. If you did make a pull request, return to '
                       + 'its website to see comments.', false)
        }
      }
    })
  }
}
