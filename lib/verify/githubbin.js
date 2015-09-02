#!/usr/bin/env node

var exec = require('child_process').exec
var request = require('request')
var user = ''

var helper = require('../helpers.js')
var userData = require('../user-data.js')

var addToList = helper.addtoList
var markChallengeCompleted = helper.markChallengeCompleted

var currentChallenge = 'githubbin'

var total = 3
var counter = 0

// verify they set up git config
// verify that user exists on GitHub (not case sensitve)
// compare the two to make sure cases match

module.exports = function verifyGitHubbinChallenge () {

  exec('git config user.username', function (err, stdout, stderr) {
    if (err) {
      addtoList('Error: ' + err.message, false)
      return helper.challengeIncomplete()
    }
    user = stdout.trim()
    if (user === '') addToList('No username found.', false)
    else {
      counter++
      addToList('Username added to Git config!', true)
      checkGitHub(user)
    }
  })

  function checkGitHub (user) {
    var options = {
      url: 'https://api.github.com/users/' + user,
      json: true,
      headers: { 'User-Agent': 'jlord'}
    }

    request(options, function (error, response, body) {
      if (error) {
        addtoList('Error: ' + err.message, false)
        return helper.challengeIncomplete()
      }
      if (!error && response.statusCode === 200) {
        counter++
        addToList("You're on GitHub!", true)
        checkCapitals(body.login, user)
      } else if (response.statusCode === 404) {
        return addToList("GitHub account matching Git config\nusername wasn't found.", false)
      }
    })
  }

  function checkCapitals (githubUsername, configUsername) {
    if (configUsername.match(githubUsername)) {
      counter++
      addToList('Username same on GitHub and\nGit config!', true)
    } else {
      addToList('GitHub & Git config usernames\ndo not match', false)
      helper.challengeIncomplete()
    }
    if (counter === total) {
      counter = 0
      markChallengeCompleted(currentChallenge)
      userData.updateData(currentChallenge)
    }
  }
}
